package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.flutter.components.ComponentAdvancedCallback
import com.adyen.checkout.googlepay.GooglePayComponentState

class GooglePayAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<GooglePayComponentState>(componentFlutterApi, componentId) {
    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        sendErrorToFlutterLayer(componentError)
    }
}
