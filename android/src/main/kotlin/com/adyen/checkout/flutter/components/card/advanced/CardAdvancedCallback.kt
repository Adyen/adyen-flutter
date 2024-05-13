package com.adyen.checkout.flutter.components.card.advanced

import ComponentFlutterInterface
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.components.ComponentHeightMessenger

class CardAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val assignCurrentComponent: () -> Unit
) : ComponentAdvancedCallback<CardComponentState>(componentFlutterApi, componentId) {
    override fun onStateChanged(state: CardComponentState) {
        ComponentHeightMessenger.sendResult(1)
    }

    override fun onSubmit(state: CardComponentState) {
        assignCurrentComponent.invoke()
        super.onSubmit(state)
    }
}
