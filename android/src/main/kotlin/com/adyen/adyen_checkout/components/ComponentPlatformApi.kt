package com.adyen.adyen_checkout.components

import ComponentPlatformInterface
import ErrorDTO
import PaymentOutcomeDTO
import PaymentResultModelDTO
import PaymentResultType
import org.json.JSONObject

class ComponentPlatformApi : ComponentPlatformInterface {

    override fun updateViewHeight(viewId: Long) {
        ComponentHeightMessenger.sendResult(viewId);
    }

    override fun onPaymentsResult(paymentsResult: PaymentOutcomeDTO) {
        handlePaymentFlowOutcome(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentOutcomeDTO) {
        handlePaymentFlowOutcome(paymentsDetailsResult)
    }

    private fun handlePaymentFlowOutcome(paymentFlowOutcomeDTO: PaymentOutcomeDTO) {
        when (paymentFlowOutcomeDTO.paymentResultType) {
            PaymentResultType.FINISHED -> onFinished(paymentFlowOutcomeDTO.result)
            PaymentResultType.ACTION -> onAction(paymentFlowOutcomeDTO.actionResponse)
            PaymentResultType.ERROR -> onError(paymentFlowOutcomeDTO.error)
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
