package com.adyen.checkout.flutter.components.base

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState

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
        sendErrorToFlutterLayer(componentError)
    }

    fun sendErrorToFlutterLayer(componentError: ComponentError) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ERROR,
                componentId = componentId,
                data = componentError.exception.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
