package com.adyen.checkout.flutter.components.instant

import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.sessions.core.SessionPaymentResult

class InstantComponentSessionCallback<T : PaymentComponentState<*>>(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentSessionCallback<T>(componentFlutterApi, componentId, onActionCallback) {
    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        super.onError(componentError)
    }

    override fun onFinished(result: SessionPaymentResult) {
        hideLoadingBottomSheet()
        super.onFinished(result)
    }
}
