package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponentState
import org.json.JSONObject

class GooglePayAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onLoadingCallback: () -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<GooglePayComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: GooglePayComponentState) {
        onLoadingCallback()
        val submitData = JSONObject()
        val paymentData = PaymentComponentData.SERIALIZER.serialize(state.data)
        submitData.put(Constants.GOOGLE_PAY_ADVANCED_PAYMENT_DATA_KEY, paymentData)
        state.paymentData?.toJson()?.let {
            submitData.put(Constants.GOOGLE_PAY_ADVANCED_EXTRA_DATA_KEY, JSONObject(it))
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
