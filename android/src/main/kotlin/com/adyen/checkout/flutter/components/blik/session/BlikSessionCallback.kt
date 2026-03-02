package com.adyen.checkout.flutter.components.blik.session

import com.adyen.checkout.blik.BlikComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface

internal class BlikSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
    private val assignCurrentComponent: () -> Unit,
) : ComponentSessionCallback<BlikComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onSubmit(state: BlikComponentState): Boolean {
        assignCurrentComponent()
        return super.onSubmit(state)
    }
}
