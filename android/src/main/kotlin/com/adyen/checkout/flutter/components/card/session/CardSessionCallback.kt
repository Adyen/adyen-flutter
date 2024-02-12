package com.adyen.checkout.flutter.components.card.session

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import PaymentResultModelDTO
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.ComponentHeightMessenger
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult

class CardSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit
) :
    SessionComponentCallback<CardComponentState> {
    override fun onFinished(result: SessionPaymentResult) {
        val paymentResult =
            PaymentResultModelDTO(
                result.sessionId,
                result.sessionData,
                result.sessionResult,
                result.resultCode,
                result.order?.mapToOrderResponseModel()
            )
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = paymentResult
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAction(action: Action) {
        onActionCallback(action)
    }

    override fun onError(componentError: ComponentError) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ERROR,
                componentId = componentId,
                data = componentError.exception.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onStateChanged(state: CardComponentState) {
        ComponentHeightMessenger.sendResult(1)
    }
}
