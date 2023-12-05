package com.adyen.adyen_checkout.components.card.session

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import SessionDTO
import android.content.Context
import android.view.View
import android.view.ViewGroup
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.doOnNextLayout
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.card.BaseCardComponent
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.ui.core.AdyenComponentView
import kotlinx.coroutines.launch
import java.util.UUID

class CardSessionFlowComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val session = creationParams?.get(SESSION_KEY) as SessionDTO
    private val sessionModel = SessionModel(id = session.id, sessionData = session.sessionData)

    init {
        activity.lifecycleScope.launch {
            when (val sessionResult = CheckoutSessionProvider.createSession(sessionModel, cardConfiguration)) {
                is CheckoutSessionResult.Error -> {
                    sessionResult.exception.message?.let { sendErrorToFlutterLayer(it) }
                    return@launch
                }

                is CheckoutSessionResult.Success -> {
                    val paymentMethod = sessionResult.checkoutSession.getPaymentMethod(PaymentMethodTypes.SCHEME)
                    if (paymentMethod == null) {
                        sendErrorToFlutterLayer("Session does not contain SCHEME payment method.")
                        return@launch
                    }

                    cardComponent = CardComponent.PROVIDER.get(
                        activity = activity,
                        checkoutSession = sessionResult.checkoutSession,
                        paymentMethod = paymentMethod,
                        configuration = cardConfiguration,
                        componentCallback = CardSessionFlowCallback(componentFlutterApi) { action -> onAction(action) },
                        key = UUID.randomUUID().toString()
                    )
                    addComponent(cardComponent)
                }
            }
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

    private fun onAction(action: Action) = cardComponent.handleAction(action, activity)

    private fun sendErrorToFlutterLayer(errorMessage: String) {
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.ERROR,
            data = errorMessage,
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    companion object {
        const val SESSION_KEY = "session"
    }
}
