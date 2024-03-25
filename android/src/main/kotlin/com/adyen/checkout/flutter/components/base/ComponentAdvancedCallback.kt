package com.adyen.checkout.flutter.components.base

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import PaymentResultDTO
import PaymentResultEnum
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.flutter.utils.Constants

abstract class ComponentAdvancedCallback<T : PaymentComponentState<*>>(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
) : ComponentCallback<T> {
    override fun onSubmit(state: T) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ONSUBMIT,
                componentId = componentId,
                data = PaymentComponentData.SERIALIZER.serialize(state.data).toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ADDITIONALDETAILS,
                componentId = componentId,
                data = ActionComponentData.SERIALIZER.serialize(actionComponentData).toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        val type: PaymentResultEnum =
            if (componentError.errorMessage.contains(Constants.SDK_PAYMENT_CANCELED_IDENTIFIER)) {
                PaymentResultEnum.CANCELLEDBYUSER
            } else {
                PaymentResultEnum.ERROR
            }

        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
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
