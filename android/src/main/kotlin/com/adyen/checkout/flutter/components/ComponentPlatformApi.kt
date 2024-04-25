package com.adyen.checkout.flutter.components

import ComponentFlutterInterface
import ComponentPlatformInterface
import ErrorDTO
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import InstantPaymentType
import PaymentEventDTO
import PaymentEventType
import PaymentResultModelDTO
import android.content.Intent
import androidx.core.util.Consumer
import androidx.core.view.KeyEventDispatcher.Component
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.components.core.internal.PaymentComponent
import com.adyen.checkout.flutter.components.googlepay.GooglePayComponentManager
import com.adyen.checkout.flutter.components.instant.InstantComponentManager
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_ADVANCED_COMPONENT_KEY
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_SESSION_COMPONENT_KEY
import com.adyen.checkout.instant.InstantPaymentComponent
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) : ComponentPlatformInterface {
    private val googlePayComponentManager: GooglePayComponentManager =
        GooglePayComponentManager(activity, sessionHolder, componentFlutterInterface)
    private val instantComponentManager: InstantComponentManager =
        InstantComponentManager(activity, componentFlutterInterface)

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

            InstantPaymentType.INSTANT,
            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onInstantPaymentPressed(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
    ) {
       when (instantPaymentConfigurationDTO.instantPaymentType) {
            InstantPaymentType.GOOGLEPAY -> googlePayComponentManager.startGooglePayScreen()
            InstantPaymentType.APPLEPAY -> return
            InstantPaymentType.INSTANT -> instantComponentManager.startInstantPaymentComponent(
                instantPaymentConfigurationDTO,
                paymentMethodResponse,
                componentId
            )
        }
    }

    override fun onDispose(componentId: String) = googlePayComponentManager.onDispose()

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean = googlePayComponentManager.handleGooglePayActivityResult(requestCode, resultCode, data)

    private fun handlePaymentEvent(
        componentId: String,
        paymentEventDTO: PaymentEventDTO
    ) {
        if (componentId == GOOGLE_PAY_SESSION_COMPONENT_KEY || componentId == GOOGLE_PAY_ADVANCED_COMPONENT_KEY) {
            googlePayComponentManager.handlePaymentEvent(paymentEventDTO)
        } else if (componentId.contains("INSTANT_")) {
            instantComponentManager.handlePaymentEvent(paymentEventDTO, componentId)
        } else {
            when (paymentEventDTO.paymentEventType) {
                PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result)
                PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
                PaymentEventType.ERROR -> onError(paymentEventDTO.error)
            }
        }
    }

    private fun onFinished(resultCode: String?) {
        val paymentResult = PaymentResultModelDTO(resultCode = resultCode)
        ComponentResultMessenger.sendResult(paymentResult)
    }

    private fun onAction(actionResponse: Map<String?, Any?>?) {
        actionResponse?.let {
            val jsonActionResponse = JSONObject(it)
            ComponentActionMessenger.sendResult(jsonActionResponse)
        }
    }

    private fun onError(error: ErrorDTO?) {
        error?.let {
            ComponentErrorMessenger.sendResult(it)
        }
    }
}
