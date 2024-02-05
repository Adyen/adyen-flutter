package com.adyen.checkout.flutter.components.googlepay

import ComponentCommunicationModel
import ComponentFlutterInterface
import PaymentResultModelDTO
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.googlepay.GooglePayComponentState
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult

class GooglePaySessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface
) : SessionComponentCallback<GooglePayComponentState> {
    override fun onAction(action: Action) {
        println("ON ACTION")
    }

    override fun onError(componentError: ComponentError) {
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.ERROR,
            data = componentError.exception.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onFinished(result: SessionPaymentResult) {
        val paymentResult = PaymentResultModelDTO(
            result.sessionId,
            result.sessionData,
            result.sessionResult,
            result.resultCode,
            result.order?.mapToOrderResponseModel()
        )
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.RESULT, paymentResult = paymentResult
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
