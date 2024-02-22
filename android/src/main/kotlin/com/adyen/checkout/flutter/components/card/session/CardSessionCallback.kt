package com.adyen.checkout.flutter.components.card.session

import ComponentFlutterInterface
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.ComponentHeightMessenger
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback

class CardSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit
) : ComponentSessionCallback<CardComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onStateChanged(state: CardComponentState) {
        ComponentHeightMessenger.sendResult(1)
    }
}
