package com.adyen.checkout.flutter.components.instant

import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.Constants
import org.json.JSONObject

class InstantComponentAdvancedCallback<T : PaymentComponentState<*>>(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<T>(componentFlutterApi, componentId) {
    override fun onSubmit(state: T) {
        val data = PaymentComponentData.Companion.SERIALIZER.serialize(state.data)
        val submitData =
            JSONObject().apply {
                put(Constants.Companion.ADVANCED_PAYMENT_DATA_KEY, data)
                put(Constants.Companion.ADVANCED_EXTRA_DATA_KEY, null)
            }
        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.ON_SUBMIT,
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
