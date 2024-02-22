package com.adyen.checkout.flutter.components.googlepay.session

import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.googlepay.GooglePayComponentState
import com.adyen.checkout.sessions.core.SessionPaymentResult

class GooglePaySessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentSessionCallback<GooglePayComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onAction(action: Action) = onActionCallback(action)

    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        sendErrorToFlutterLayer(componentError)
    }

    override fun onFinished(result: SessionPaymentResult) {
        hideLoadingBottomSheet()
        sendPaymentResultToFlutterLayer(result)
    }
}
