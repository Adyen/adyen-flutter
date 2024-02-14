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
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.GooglePayComponentManager
import com.adyen.checkout.flutter.session.SessionHolder
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) : ComponentPlatformInterface {
    private var googlePayComponentManager: GooglePayComponentManager? = null
    private val paymentFinishedFlow = MutableStateFlow<Boolean?>(null)


    override fun updateViewHeight(viewId: Long) {
        ComponentHeightMessenger.sendResult(viewId)
    }

    override fun onPaymentsResult(paymentsResult: PaymentEventDTO, componentId: String) {
        handlePaymentEvent(paymentsResult, componentId)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO, componentId: String) {
        handlePaymentEvent(paymentsDetailsResult, componentId)
    }

    override fun isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        val paymentMethodJson = JSONObject(paymentMethodResponse)
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
        when (instantPaymentConfigurationDTO.instantPaymentType) {
            InstantPaymentType.GOOGLEPAYSESSION,
            InstantPaymentType.GOOGLEPAYADVANCED -> {
                googlePayComponentManager = GooglePayComponentManager(activity)
                googlePayComponentManager?.isGooglePayAvailable(
                    paymentMethod,
                    componentId,
                    sessionHolder,
                    componentFlutterInterface,
                    instantPaymentConfigurationDTO,
                    callback
                )
            }

            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onInstantPaymentPressed(instantPaymentType: InstantPaymentType, componentId: String) {
        when (instantPaymentType) {
            InstantPaymentType.GOOGLEPAYSESSION,
            InstantPaymentType.GOOGLEPAYADVANCED -> googlePayComponentManager?.startGooglePayScreen(componentId)

            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onDispose(componentId: String) {
        googlePayComponentManager?.onDispose(componentId)
    }

    fun handleActivityResult(
        requestCode: Int, resultCode: Int, data: Intent?
    ): Boolean {
        return googlePayComponentManager?.handleGooglePayActivityResult(requestCode, resultCode, data) ?: false
    }

    private fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO, componentId: String) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result, componentId)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse, componentId)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error, componentId)
        }
    }

    private fun onFinished(resultCode: String?, componentId: String) {
        val paymentResult = PaymentResultModelDTO(resultCode = resultCode)
        ComponentResultMessenger.sendResult(paymentResult)
        activity.lifecycleScope.launch {
            paymentFinishedFlow.emit(true)
        }

    }

    private fun onAction(actionResponse: Map<String?, Any?>?, componentId: String) {
        actionResponse?.let {
            val jsonActionResponse = JSONObject(it)
            ComponentActionMessenger.sendResult(jsonActionResponse)
        }
    }

    private fun onError(error: ErrorDTO?, componentId: String) {
        error?.let {
            ComponentErrorMessenger.sendResult(it)
        }
    }
}
