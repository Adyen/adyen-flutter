package com.adyen.checkout.flutter.components.instant.advanced

import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.instant.InstantComponentState
import org.json.JSONObject

class InstantComponentAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<InstantComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: InstantComponentState) {
        val data = PaymentComponentData.SERIALIZER.serialize(state.data)
        val submitData =
            JSONObject().apply {
                put(Constants.ADVANCED_PAYMENT_DATA_KEY, data)
                put(Constants.ADVANCED_EXTRA_DATA_KEY, null)
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
}
