package com.adyen.checkout.flutter.components.card.session

import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface

internal class CardSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
    private val assignCurrentComponent: () -> Unit,
) : ComponentSessionCallback<CardComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onSubmit(state: CardComponentState): Boolean {
        assignCurrentComponent()
        return super.onSubmit(state)
    }
}
