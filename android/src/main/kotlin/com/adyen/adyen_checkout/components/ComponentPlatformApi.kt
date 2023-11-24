package com.adyen.adyen_checkout.components

import ComponentPlatformInterface
import ErrorDTO
import PaymentFlowOutcomeDTO
import PaymentFlowResultType
import PaymentResultModelDTO
import org.json.JSONObject

class ComponentPlatformApi : ComponentPlatformInterface {

    override fun updateViewHeight(viewId: Long) {
        ComponentHeightMessenger.sendResult(viewId);
    }

    override fun onPaymentsResult(paymentsResult: PaymentFlowOutcomeDTO) {
        handlePaymentFlowOutcome(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentFlowOutcomeDTO) {
        handlePaymentFlowOutcome(paymentsDetailsResult)
    }

    private fun handlePaymentFlowOutcome(paymentFlowOutcomeDTO: PaymentFlowOutcomeDTO) {
        when (paymentFlowOutcomeDTO.paymentFlowResultType) {
            PaymentFlowResultType.FINISHED -> onFinished(paymentFlowOutcomeDTO.result)
            PaymentFlowResultType.ACTION -> onAction(paymentFlowOutcomeDTO.actionResponse)
            PaymentFlowResultType.ERROR -> onError(paymentFlowOutcomeDTO.error)
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
