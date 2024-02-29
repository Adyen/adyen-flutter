package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.googlepay.GooglePayComponentState

class GooglePayAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onLoadingCallback: () -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentAdvancedCallback<GooglePayComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: GooglePayComponentState) {
        onLoadingCallback()
        super.onSubmit(state)
    }

    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        super.onError(componentError)
    }
}
