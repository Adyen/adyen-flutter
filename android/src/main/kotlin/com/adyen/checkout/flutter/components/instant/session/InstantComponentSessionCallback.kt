package com.adyen.checkout.flutter.components.instant.session

import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.googlepay.GooglePayComponentState
import com.adyen.checkout.instant.InstantComponentState
import com.adyen.checkout.sessions.core.SessionPaymentResult

class InstantComponentSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onLoadingCallback: () -> Unit,
    private val onActionCallback: (Action) -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentSessionCallback<InstantComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onLoading(isLoading: Boolean) {
        onLoadingCallback()
    }

    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        super.onError(componentError)
    }

    override fun onFinished(result: SessionPaymentResult) {
        hideLoadingBottomSheet()
        super.onFinished(result)
    }
}
