package com.adyen.checkout.flutter.components.card.session

import ComponentFlutterInterface
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback

internal class CardSessionCallback(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
    private val onActionCallback: (Action) -> Unit,
    private val assignCurrentComponent: () -> Unit,
    private val setPaymentInProgress: (Boolean) -> Unit,
) : ComponentSessionCallback<CardComponentState>(componentFlutterApi, componentId, onActionCallback) {
    override fun onSubmit(state: CardComponentState): Boolean {
        assignCurrentComponent()
        return super.onSubmit(state)
    }

    override fun onLoading(isLoading: Boolean) {
        setPaymentInProgress.invoke(isLoading)
        super.onLoading(isLoading)
    }
}
