package com.adyen.checkout.flutter.components.googlepay

import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponentState
import org.json.JSONObject

class GooglePayAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<GooglePayComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: GooglePayComponentState) {
        onLoading()
        val data = PaymentComponentData.SERIALIZER.serialize(state.data)
        val extra = state.paymentData?.toJson()
        val submitData =
            JSONObject().apply {
                put(Constants.ADVANCED_PAYMENT_DATA_KEY, data)
                extra?.let {
                    put(Constants.ADVANCED_EXTRA_DATA_KEY, JSONObject(it))
                }
            }
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.ON_SUBMIT,
                componentId = componentId,
                data = submitData.toString(),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        super.onError(componentError)
    }

    private fun onLoading() {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
