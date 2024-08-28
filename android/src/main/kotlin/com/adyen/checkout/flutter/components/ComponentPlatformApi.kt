package com.adyen.checkout.flutter.components

import ActionComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentFlutterInterface
import ComponentPlatformInterface
import ErrorDTO
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import InstantPaymentType
import PaymentEventDTO
import PaymentEventType
import PaymentResultDTO
import PaymentResultModelDTO
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.action.ActionComponentManager
import com.adyen.checkout.flutter.components.card.CardComponentManager
import com.adyen.checkout.flutter.components.googlepay.GooglePayComponentManager
import com.adyen.checkout.flutter.components.instant.InstantComponentManager
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.flutter.utils.Constants.Companion.CARD_SESSION_COMPONENT_KEY
import com.adyen.checkout.flutter.utils.Constants.Companion.CARD_ADVANCED_COMPONENT_KEY
import com.adyen.checkout.redirect.RedirectComponent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
) : ComponentPlatformInterface {
    private val cardComponentManager: CardComponentManager =
        CardComponentManager(
            activity,
            componentFlutterInterface,
            flutterPluginBinding,
            sessionHolder,
            ::onDispose,
            ::assignCurrentComponent
        )
    private val googlePayComponentManager: GooglePayComponentManager =
        GooglePayComponentManager(activity, sessionHolder, componentFlutterInterface, ::assignCurrentComponent)
    private val instantComponentManager: InstantComponentManager =
        InstantComponentManager(activity, componentFlutterInterface, sessionHolder, ::assignCurrentComponent)
    private val actionComponentManager: ActionComponentManager =
        ActionComponentManager(activity, componentFlutterInterface, ::assignCurrentComponent)
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    private var currentComponent: ActionHandlingComponent? = null

    init {
        cardComponentManager.registerComponentViewFactories()
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
        val paymentMethodJson = JSONObject(paymentMethodResponse)
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
        when (instantPaymentConfigurationDTO.instantPaymentType) {
            InstantPaymentType.GOOGLEPAY ->
                googlePayComponentManager.initialize(
                    paymentMethod,
                    componentId,
                    instantPaymentConfigurationDTO,
                    callback
                )

            InstantPaymentType.INSTANT, InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onInstantPaymentPressed(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        encodedPaymentMethod: String,
        componentId: String,
    ) {
        when (instantPaymentConfigurationDTO.instantPaymentType) {
            InstantPaymentType.GOOGLEPAY -> googlePayComponentManager.start()
            InstantPaymentType.APPLEPAY -> return
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
        googlePayComponentManager.onDispose(componentId)
        instantComponentManager.onDispose(componentId)
        actionComponentManager.onDispose(componentId)
    }

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean {
        return when (requestCode) {
            Constants.GOOGLE_PAY_COMPONENT_REQUEST_CODE -> {
                googlePayComponentManager.handleGooglePayActivityResult(resultCode, data)
                true
            }

            else -> false
        }
    }

    private fun handlePaymentEvent(
        componentId: String,
        paymentEventDTO: PaymentEventDTO
    ) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result, componentId)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error, componentId)
        }
    }

    private fun onFinished(
        resultCode: String?,
        componentId: String
    ) {
        resetPaymentInProgress(componentId)
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

    private fun onAction(action: Map<String?, Any?>?) {
        action?.let {
            val actionJson = JSONObject(it)
            currentComponent?.handleAction(Action.SERIALIZER.deserialize(actionJson), activity)
        }
    }

    private fun onError(
        error: ErrorDTO?,
        componentId: String
    ) {
        resetPaymentInProgress(componentId)
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
            intent.data?.toString().orEmpty()
                .startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)
        ) {
            currentComponent?.handleIntent(intent)
        }
    }

    // Reset isPaymentInProgress to false again. We can remove this when the pay button handles the pressed state itself.
    private fun resetPaymentInProgress(componentId: String) {
        when (componentId) {
            CARD_ADVANCED_COMPONENT_KEY, CARD_SESSION_COMPONENT_KEY -> cardComponentManager.setPaymentInProgress(false)
        }
    }
}
