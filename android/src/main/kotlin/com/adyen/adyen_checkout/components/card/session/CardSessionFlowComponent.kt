package com.adyen.adyen_checkout.components.card.session

import ComponentFlutterApi
import SessionDTO
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.doOnNextLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.card.BaseCardComponent
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.ui.core.AdyenComponentView
import kotlinx.coroutines.launch
import java.util.UUID

class CardSessionFlowComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val session = creationParams?.get("session") as SessionDTO
    private val sessionModel = SessionModel(id = session.id, sessionData = session.sessionData)

    init {
        activity.lifecycleScope.launch {
            val checkoutSession: CheckoutSession? = getCheckoutSession(sessionModel, cardConfiguration)
            if (checkoutSession == null) {
                Log.e("AdyenCheckout", "Failed to fetch session")
                //TODO error handling
                //_cardViewState.emit(CardViewState.Error)
                return@launch
            }

            val paymentMethod = checkoutSession.getPaymentMethod(PaymentMethodTypes.SCHEME)
            if (paymentMethod == null) {
                Log.e("AdyenCheckout", "Session does not contain SCHEME payment method")
                //TODO error handling
                //_cardViewState.emit(CardViewState.Error)
                return@launch
            }

            cardComponent = CardComponent.PROVIDER.get(
                activity = activity,
                checkoutSession = checkoutSession,
                paymentMethod = paymentMethod,
                configuration = cardConfiguration,
                componentCallback = CardSessionFlowCallback(componentFlutterApi) { action -> onAction(action) },
                key = UUID.randomUUID().toString()
            )

            addComponent(cardComponent)
        }
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)

        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams = ConstraintLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
    }


    private suspend fun getCheckoutSession(
        sessionModel: SessionModel,
        cardConfiguration: CardConfiguration,
    ): CheckoutSession? {
        return when (val result = CheckoutSessionProvider.createSession(sessionModel, cardConfiguration)) {
            is CheckoutSessionResult.Success -> result.checkoutSession
            is CheckoutSessionResult.Error -> null
        }
    }

    private fun onAction(action: Action) = cardComponent.handleAction(action, activity)
}
