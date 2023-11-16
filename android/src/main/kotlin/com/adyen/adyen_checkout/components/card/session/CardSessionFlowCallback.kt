package com.adyen.adyen_checkout.components.card.session

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import PaymentResultModelDTO
import android.util.Log
import com.adyen.adyen_checkout.components.ComponentHeightMessenger
import com.adyen.adyen_checkout.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult

class CardSessionFlowCallback(
    private val componentFlutterApi: ComponentFlutterApi,
    private val onActionCallback: (Action) -> Unit
) :
    SessionComponentCallback<CardComponentState> {
    override fun onFinished(result: SessionPaymentResult) {
        val paymentResult = PaymentResultModelDTO(
            result.sessionId,
            result.sessionData,
            result.sessionResult,
            result.resultCode,
            result.order?.mapToOrderResponseModel()
        )

        val model = ComponentCommunicationModel(
            ComponentCommunicationType.RESULT,
            data = "",
            paymentResult = paymentResult
        )

        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAction(action: Action) {
        onActionCallback(action)
    }

    override fun onError(componentError: ComponentError) {
        Log.d("AdyenCheckout", componentError.exception.toString())
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.ERROR,
            data = componentError.exception.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onStateChanged(state: CardComponentState) {
        ComponentHeightMessenger.sendResult(1)
    }
}
