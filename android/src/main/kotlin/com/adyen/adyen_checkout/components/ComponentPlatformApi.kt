package com.adyen.adyen_checkout.components

import ComponentPlatformInterface
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
        println("PAYMENT FLOW $paymentFlowOutcomeDTO")
        when (paymentFlowOutcomeDTO.paymentFlowResultType) {
            PaymentFlowResultType.FINISHED -> {
                val paymentResult = PaymentResultModelDTO(resultCode = paymentFlowOutcomeDTO.result)
                ComponentResultMessenger.sendResult(paymentResult)
            }
            PaymentFlowResultType.ACTION -> {
                paymentFlowOutcomeDTO.actionResponse?.let {
                    val jsonActionResponse = JSONObject(it)
                    ComponentActionMessenger.sendResult(jsonActionResponse)
                }
            }

            PaymentFlowResultType.ERROR -> TODO()
        }
    }

}
