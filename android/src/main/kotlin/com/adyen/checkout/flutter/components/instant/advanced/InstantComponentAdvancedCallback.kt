package com.adyen.checkout.flutter.components.instant.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponentState
import com.adyen.checkout.instant.InstantComponentState
import com.adyen.checkout.instant.InstantPaymentComponent
import org.json.JSONObject

class InstantComponentAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onLoadingCallback: (componentId: String) -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<InstantComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: InstantComponentState) {
        onLoadingCallback(componentId)
        val data = PaymentComponentData.SERIALIZER.serialize(state.data)
        val submitData =
            JSONObject().apply {
                put(Constants.GOOGLE_PAY_ADVANCED_PAYMENT_DATA_KEY, data)
            }
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ONSUBMIT,
                componentId = componentId,
                data = submitData.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        super.onError(componentError)
    }
}
