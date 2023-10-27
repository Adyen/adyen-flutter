package com.adyen.adyen_checkout.components.card

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData

class CardCallback(private val componentFlutterApi: ComponentFlutterApi) : ComponentCallback<CardComponentState> {
    override fun onSubmit(state: CardComponentState) {
        val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.PAYMENTCOMPONENT,
            data = paymentComponentJson.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        println("On additional details")
    }

    override fun onError(componentError: ComponentError) {
        println("Error")
    }

    override fun onStateChanged(state: CardComponentState) {
        super.onStateChanged(state)

        println("State changed ${state.isInputValid}")
    }


}
