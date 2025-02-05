package com.adyen.checkout.flutter.components.card.advanced

import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface

internal class CardAdvancedCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val assignCurrentComponent: () -> Unit,
) : ComponentAdvancedCallback<CardComponentState>(componentFlutterApi, componentId) {
    override fun onSubmit(state: CardComponentState) {
        assignCurrentComponent.invoke()
        super.onSubmit(state)
    }
}
