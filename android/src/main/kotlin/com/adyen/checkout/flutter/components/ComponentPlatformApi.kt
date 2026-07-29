package com.adyen.checkout.flutter.components

import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.action.ActionComponentManager
import com.adyen.checkout.flutter.components.instant.InstantComponentManager
import com.adyen.checkout.flutter.components.v2.AdyenComponentFactory
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.generated.ActionComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.ComponentPlatformInterface
import com.adyen.checkout.flutter.generated.ErrorDTO
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.InstantPaymentSetupResultDTO
import com.adyen.checkout.flutter.generated.InstantPaymentType
import com.adyen.checkout.flutter.generated.OnPlatformEventStreamHandler
import com.adyen.checkout.flutter.generated.PaymentEventDTO
import com.adyen.checkout.flutter.generated.PaymentEventType
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.generated.PaymentResultModelDTO
import com.adyen.checkout.flutter.generated.SessionCheckoutFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.redirect.old.RedirectComponent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val checkoutHolder: CheckoutHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val adyenFlutterInterface: AdyenFlutterInterface,
    private val sessionCheckoutFlutterInterface: SessionCheckoutFlutterInterface,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
) : ComponentPlatformInterface {
    private var platformEventHandler: ComponentPlatformEventHandler = ComponentPlatformEventHandler()

    private val instantComponentManager: InstantComponentManager =
        InstantComponentManager(
            activity,
            checkoutHolder,
            componentFlutterInterface,
            ::assignCurrentComponent,
            ::handleComponentAction
        )
    private val actionComponentManager: ActionComponentManager =
        ActionComponentManager(activity, componentFlutterInterface, ::assignCurrentComponent)
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    private var currentComponent: ActionHandlingComponent? = null

    init {
        flutterPluginBinding?.let { binding ->
            OnPlatformEventStreamHandler.register(binding.binaryMessenger, platformEventHandler)
            binding.platformViewRegistry.registerViewFactory(
                AdyenComponentFactory.ADYEN_COMPONENT_SESSION,
                AdyenComponentFactory(
                    activity = activity,
                    adyenFlutterInterface = adyenFlutterInterface,
                    sessionCheckoutFlutterInterface = sessionCheckoutFlutterInterface,
                    viewTypeId = AdyenComponentFactory.ADYEN_COMPONENT_SESSION,
                    onDispose = ::onDispose,
                    checkoutHolder = checkoutHolder,
                    platformEventHandler = platformEventHandler,
                )
            )
            binding.platformViewRegistry.registerViewFactory(
                AdyenComponentFactory.ADYEN_COMPONENT_ADVANCED,
                AdyenComponentFactory(
                    activity = activity,
                    adyenFlutterInterface = adyenFlutterInterface,
                    sessionCheckoutFlutterInterface = sessionCheckoutFlutterInterface,
                    platformEventHandler = platformEventHandler,
                    viewTypeId = AdyenComponentFactory.ADYEN_COMPONENT_ADVANCED,
                    onDispose = ::onDispose,
                    checkoutHolder = checkoutHolder,
                )
            )
        }
    }

    // Update view height from Flutter when required.
    // The initial viewport height is being calculated by the OnGlobalLayoutListener from the component view. Therefore the method body is empty.
    override fun updateViewHeight(viewId: Long) = Unit

    override fun onPaymentsResult(
        componentId: String,
        paymentsResult: PaymentEventDTO
    ) = handlePaymentEvent(componentId, paymentsResult)

    override fun onPaymentsDetailsResult(
        componentId: String,
        paymentsDetailsResult: PaymentEventDTO
    ) = handlePaymentEvent(componentId, paymentsDetailsResult)

    override fun isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        when (instantPaymentConfigurationDTO.instantPaymentType) {
            // Google Pay now renders through the generic v6 platform-view path
            // (AdyenComponentFactory), not through this instant-payment mechanism.
            InstantPaymentType.GOOGLE_PAY,
            InstantPaymentType.INSTANT,
            InstantPaymentType.APPLE_PAY -> return
        }
    }

    override fun onInstantPaymentPressed(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        encodedPaymentMethod: String,
        componentId: String,
    ) {
        when (instantPaymentConfigurationDTO.instantPaymentType) {
            // Google Pay now renders through the generic v6 platform-view path
            // (AdyenComponentFactory), not through this instant-payment mechanism.
            InstantPaymentType.GOOGLE_PAY, InstantPaymentType.APPLE_PAY -> return
            InstantPaymentType.INSTANT ->
                instantComponentManager.start(
                    instantPaymentConfigurationDTO,
                    encodedPaymentMethod,
                    componentId
                )
        }
    }

    override fun handleAction(
        actionComponentConfiguration: ActionComponentConfigurationDTO,
        componentId: String,
        actionResponse: Map<String?, Any?>?
    ) = actionComponentManager.handleAction(actionComponentConfiguration, componentId, actionResponse)

    override fun onDispose(componentId: String) {
        activity.removeOnNewIntentListener(intentListener)
        currentComponent = null
    }

    private fun handlePaymentEvent(
        componentId: String,
        paymentEventDTO: PaymentEventDTO
    ) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result, componentId)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.data)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error, componentId)
            PaymentEventType.UPDATE -> onUpdate(paymentEventDTO.data, componentId)
        }
    }

    private fun onFinished(
        resultCode: String?,
        componentId: String
    ) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult =
                    PaymentResultDTO(
                        type = PaymentResultEnum.FINISHED,
                        result = PaymentResultModelDTO(resultCode = resultCode)
                    ),
            )
        componentFlutterInterface.onComponentCommunication(model) {}
        hideLoadingBottomSheet()
    }

    private fun onAction(actionResponse: Map<String?, Any?>?) {
        actionResponse?.let {
            val action = Action.SERIALIZER.deserialize(JSONObject(it))
            handleComponentAction(action)
        }
    }

    private fun handleComponentAction(action: Action) = currentComponent?.handleAction(action, activity)

    private fun onError(
        error: ErrorDTO?,
        componentId: String
    ) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult =
                    PaymentResultDTO(
                        type = PaymentResultEnum.ERROR,
                        reason = error?.errorMessage,
                    ),
            )
        componentFlutterInterface.onComponentCommunication(model) {}
        hideLoadingBottomSheet()
    }

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    private fun assignCurrentComponent(currentComponent: ActionHandlingComponent?) {
        this.currentComponent = currentComponent
        setupIntentListener()
    }

    private fun setupIntentListener() {
        activity.removeOnNewIntentListener(intentListener)
        activity.addOnNewIntentListener(intentListener)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.data != null &&
            intent.data
                ?.toString()
                .orEmpty()
                .startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)
        ) {
            currentComponent?.handleIntent(intent)
        }
    }

    private fun onUpdate(
        data: Map<String?, Any?>?,
        componentId: String
    ) = Unit
}
