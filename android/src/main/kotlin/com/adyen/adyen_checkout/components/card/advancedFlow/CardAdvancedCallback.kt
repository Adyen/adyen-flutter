package com.adyen.adyen_checkout.components.card.advancedFlow

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import com.adyen.adyen_checkout.components.ComponentHeightMessenger
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData

class CardAdvancedCallback(private val componentFlutterApi: ComponentFlutterInterface) :
    ComponentCallback<CardComponentState> {
    override fun onSubmit(state: CardComponentState) {
        val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.ONSUBMIT,
            data = paymentComponentJson.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        val actionComponentJson = ActionComponentData.SERIALIZER.serialize(actionComponentData)
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.ADDITIONALDETAILS,
            data = actionComponentJson.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
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
