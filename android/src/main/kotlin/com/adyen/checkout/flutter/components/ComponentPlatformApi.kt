package com.adyen.checkout.flutter.components

import ComponentPlatformInterface
import ErrorDTO
import PaymentEventDTO
import PaymentEventType
import PaymentResultModelDTO
import org.json.JSONObject

class ComponentPlatformApi : ComponentPlatformInterface {

    override fun updateViewHeight(viewId: Long) {
        ComponentHeightMessenger.sendResult(viewId)
    }

    override fun onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentsDetailsResult)
    }

    private fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error)
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
