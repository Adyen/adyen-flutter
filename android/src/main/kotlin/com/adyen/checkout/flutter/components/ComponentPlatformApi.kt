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
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.action.ActionComponentManager
import com.adyen.checkout.flutter.components.googlepay.GooglePayComponentManager
import com.adyen.checkout.flutter.components.instant.InstantComponentManager
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.redirect.RedirectComponent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) : ComponentPlatformInterface {
    private val googlePayComponentManager: GooglePayComponentManager =
        GooglePayComponentManager(activity, sessionHolder, componentFlutterInterface)
    private val instantComponentManager: InstantComponentManager =
        InstantComponentManager(activity, componentFlutterInterface, sessionHolder)
    private val actionComponentManager: ActionComponentManager =
        ActionComponentManager(activity, componentFlutterInterface, ::assignCurrentComponent)
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    private var currentComponent: ActionHandlingComponent? = null

    companion object {
        val currentComponentStateFlow = MutableStateFlow<ActionHandlingComponent?>(null)
    }

    init {
        activity.lifecycleScope.launch {
            currentComponentStateFlow.collect { value -> assignCurrentComponent(value) }
        }
    }

    override fun updateViewHeight(viewId: Long) = ComponentHeightMessenger.sendResult(viewId)

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
                googlePayComponentManager.isGooglePayAvailable(
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
        val currentComponent =
            when (instantPaymentConfigurationDTO.instantPaymentType) {
                InstantPaymentType.GOOGLEPAY -> googlePayComponentManager.startGooglePayComponent()
                InstantPaymentType.APPLEPAY -> return
                InstantPaymentType.INSTANT ->
                    instantComponentManager.startInstantComponent(
                        instantPaymentConfigurationDTO,
                        encodedPaymentMethod,
                        componentId
                    )
            }
        assignCurrentComponent(currentComponent)
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
}
