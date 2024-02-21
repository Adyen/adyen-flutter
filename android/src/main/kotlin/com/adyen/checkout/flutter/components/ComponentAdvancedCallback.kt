package com.adyen.checkout.flutter.components

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
        sendPaymentComponentToFlutterLayer(state)
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        sendActionToFlutterLayer(actionComponentData)
    }

    override fun onError(componentError: ComponentError) {
        sendErrorToFlutterLayer(componentError)
    }

    fun sendPaymentComponentToFlutterLayer(state: T) {
        val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ONSUBMIT,
                componentId = componentId,
                data = paymentComponentJson.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    fun sendActionToFlutterLayer(actionComponentData: ActionComponentData) {
        val actionComponentJson = ActionComponentData.SERIALIZER.serialize(actionComponentData)
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ADDITIONALDETAILS,
                componentId = componentId,
                data = actionComponentJson.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
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
