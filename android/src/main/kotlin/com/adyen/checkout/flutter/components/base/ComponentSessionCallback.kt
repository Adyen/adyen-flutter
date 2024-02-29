package com.adyen.checkout.flutter.components.base

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import PaymentResultModelDTO
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult

abstract class ComponentSessionCallback<T : PaymentComponentState<*>>(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
) : SessionComponentCallback<T> {
    override fun onAction(action: Action) = onActionCallback(action)

    override fun onError(componentError: ComponentError) {
        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.ERROR,
                componentId = componentId,
                data = componentError.exception.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

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
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = paymentResult
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
