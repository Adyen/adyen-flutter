package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.googlepay.GooglePayComponentState

class GooglePayAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentCallback<GooglePayComponentState> {
    override fun onSubmit(state: GooglePayComponentState) {
        val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ONSUBMIT,
                componentId = componentId,
                data = paymentComponentJson.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        val actionComponentJson = ActionComponentData.SERIALIZER.serialize(actionComponentData)
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ADDITIONALDETAILS,
                componentId = componentId,
                data = actionComponentJson.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.ERROR,
                componentId = componentId,
                data = componentError.exception.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
