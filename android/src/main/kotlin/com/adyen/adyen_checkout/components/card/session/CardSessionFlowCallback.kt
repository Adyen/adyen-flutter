package com.adyen.adyen_checkout.components.card.session

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import android.util.Log
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult

class CardSessionFlowCallback(
    private val componentFlutterApi: ComponentFlutterApi,
    private val onActionCallback: (Action) -> Unit
) :
    SessionComponentCallback<CardComponentState> {
    override fun onFinished(result: SessionPaymentResult) {
        TODO("Not yet implemented")
    }

    override fun onAction(action: Action) {
        onActionCallback(action)
    }

    override fun onError(componentError: ComponentError) {
        Log.d("AdyenCheckout", componentError.exception.toString())
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.ERROR,
            data = componentError.exception.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }


}
