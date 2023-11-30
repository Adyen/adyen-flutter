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
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.card.BaseCardComponent
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import com.adyen.checkout.ui.core.AdyenComponentView
import org.json.JSONObject
import java.util.UUID

class CardSessionFlowComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val session = creationParams?.get(SESSION_KEY) as SessionDTO
    private val paymentMethodString = creationParams?.get(PAYMENT_METHOD_KEY) as String
    private val isStoredPaymentMethod = creationParams?.get(IS_STORED_PAYMENT_METHOD) as Boolean

    init {
        val checkoutSessionResponse = SessionSetupResponse.SERIALIZER.deserialize(JSONObject(session.sessionSetupResponse))
        val checkoutSession = CheckoutSession(sessionSetupResponse = checkoutSessionResponse, order = null)

        cardComponent = createCardComponent(checkoutSession)
        addComponent(cardComponent)

//        activity.lifecycleScope.launch {
//            when (val sessionResult = CheckoutSessionProvider.createSession(sessionModel, cardConfiguration)) {
//                is CheckoutSessionResult.Error -> {
//                    sessionResult.exception.message?.let { sendErrorToFlutterLayer(it) }
//                    return@launch
//                }
//
//                is CheckoutSessionResult.Success -> {
//                    val paymentMethod =
//                        sessionResult.checkoutSession.sessionSetupResponse.paymentMethodsApiResponse?.storedPaymentMethods?.first()
//                    if (paymentMethod == null) {
//                        sendErrorToFlutterLayer("Session does not contain SCHEME payment method.")
//                        return@launch
//                    }
//                }
//            }
//        }
    }

    private fun createCardComponent(checkoutSession: CheckoutSession): CardComponent {
        val paymentMethodJson = JSONObject(paymentMethodString)
        when (isStoredPaymentMethod) {
            true -> {
                val storedPaymentMethod = StoredPaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    checkoutSession = checkoutSession,
                    storedPaymentMethod = storedPaymentMethod,
                    configuration = cardConfiguration,
                    componentCallback = CardSessionFlowCallback(componentFlutterApi) { action -> onAction(action) },
                    key = UUID.randomUUID().toString()
                )
            }

            false -> {
                val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    checkoutSession = checkoutSession,
                    paymentMethod = paymentMethod,
                    configuration = cardConfiguration,
                    componentCallback = CardSessionFlowCallback(componentFlutterApi) { action -> onAction(action) },
                    key = UUID.randomUUID().toString()
                )
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
