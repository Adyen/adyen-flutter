package com.adyen.checkout.flutter.components.blik.advanced

import com.adyen.checkout.blik.BlikComponentState
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface

internal class BlikAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val assignCurrentComponent: () -> Unit,
) : ComponentAdvancedCallback<BlikComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: BlikComponentState) {
        assignCurrentComponent.invoke()
        super.onSubmit(state)
    }
}
