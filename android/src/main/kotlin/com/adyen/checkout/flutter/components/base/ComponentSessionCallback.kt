package com.adyen.checkout.flutter.components.base

import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.generated.PaymentResultModelDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult

abstract class ComponentSessionCallback<T : PaymentComponentState<*>>(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
) : SessionComponentCallback<T> {
    override fun onAction(action: Action) = onActionCallback(action)

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
                paymentResult =
                    PaymentResultDTO(
                        type = PaymentResultEnum.FINISHED,
                        result = paymentResult
                    )
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        val type: PaymentResultEnum =
            if (componentError.errorMessage.contains(Constants.SDK_PAYMENT_CANCELED_IDENTIFIER) ||
                (componentError.exception is com.adyen.checkout.core.exception.CancellationException) ||
                (componentError.exception is com.adyen.checkout.adyen3ds2.Cancelled3DS2Exception)
            )
                PaymentResultEnum.CANCELLED_BY_USER
            else
                PaymentResultEnum.ERROR

        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult =
                    PaymentResultDTO(
                        type = type,
                        reason = componentError.exception.toString()
                    ),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
