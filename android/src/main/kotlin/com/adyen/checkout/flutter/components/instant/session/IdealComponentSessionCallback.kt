package com.adyen.checkout.flutter.components.instant.session

import ComponentFlutterInterface
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.ideal.IdealComponentState
import com.adyen.checkout.sessions.core.SessionPaymentResult

class IdealComponentSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
    private val hideLoadingBottomSheet: () -> Unit,
) : ComponentSessionCallback<IdealComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onError(componentError: ComponentError) {
        hideLoadingBottomSheet()
        super.onError(componentError)
    }

    override fun onFinished(result: SessionPaymentResult) {
        hideLoadingBottomSheet()
        super.onFinished(result)
    }
}
