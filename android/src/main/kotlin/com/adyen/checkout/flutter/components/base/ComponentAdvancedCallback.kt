package com.adyen.checkout.flutter.components.base

import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.utils.Constants

abstract class ComponentAdvancedCallback<T : PaymentComponentState<*>>(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
) : ComponentCallback<T> {
    override fun onSubmit(state: T) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ON_SUBMIT,
                componentId = componentId,
                data = PaymentComponentData.SERIALIZER.serialize(state.data).toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ADDITIONAL_DETAILS,
                componentId = componentId,
                data = ActionComponentData.SERIALIZER.serialize(actionComponentData).toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        val type: PaymentResultEnum =
            if (componentError.errorMessage.contains(Constants.SDK_PAYMENT_CANCELED_IDENTIFIER) ||
                (componentError.exception is com.adyen.checkout.core.old.exception.CancellationException) ||
                (componentError.exception is com.adyen.checkout.threeds2.old.Cancelled3DS2Exception)
            )
                PaymentResultEnum.CANCELLED_BY_USER
            else
                PaymentResultEnum.ERROR

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
