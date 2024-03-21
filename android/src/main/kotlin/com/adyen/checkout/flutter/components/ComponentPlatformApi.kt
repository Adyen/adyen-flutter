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
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.GooglePayComponentManager
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_ADVANCED_COMPONENT_KEY
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_SESSION_COMPONENT_KEY
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) : ComponentPlatformInterface {
    private var googlePayComponentManager: GooglePayComponentManager =
        GooglePayComponentManager(activity, sessionHolder, componentFlutterInterface)

    override fun updateViewHeight(viewId: Long) = ComponentHeightMessenger.sendResult(viewId)

    override fun onPaymentsResult(componentId: String, paymentsResult: PaymentEventDTO) =
        handlePaymentEvent(componentId, paymentsResult)

    override fun onPaymentsDetailsResult(componentId: String, paymentsDetailsResult: PaymentEventDTO) =
        handlePaymentEvent(componentId, paymentsDetailsResult)

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

            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onInstantPaymentPressed(
        instantPaymentType: InstantPaymentType,
        componentId: String
    ) {
        when (instantPaymentType) {
            InstantPaymentType.GOOGLEPAY -> googlePayComponentManager.startGooglePayScreen()
            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onDispose(componentId: String) = googlePayComponentManager.onDispose()

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean = googlePayComponentManager.handleGooglePayActivityResult(requestCode, resultCode, data)

    private fun handlePaymentEvent(componentId: String, paymentEventDTO: PaymentEventDTO) {
        if (componentId == GOOGLE_PAY_SESSION_COMPONENT_KEY || componentId == GOOGLE_PAY_ADVANCED_COMPONENT_KEY) {
            googlePayComponentManager.handlePaymentEvent(paymentEventDTO)
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
