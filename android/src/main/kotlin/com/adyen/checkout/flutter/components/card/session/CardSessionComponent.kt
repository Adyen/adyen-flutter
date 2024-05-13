package com.adyen.checkout.flutter.components.card.session

import ComponentFlutterInterface
import android.content.Context
import android.view.View
import android.view.ViewGroup
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.doOnNextLayout
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.R
import com.adyen.checkout.flutter.components.card.BaseCardComponent
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import com.adyen.checkout.ui.core.AdyenComponentView
import org.json.JSONObject
import java.util.UUID

class CardSessionComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val sessionHolder: SessionHolder,
    context: Context,
    id: Int,
    creationParams: Map<*, *>
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
    private val isStoredPaymentMethod = creationParams[IS_STORED_PAYMENT_METHOD_KEY] as Boolean? ?: false
    private val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""

    init {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession =
            CheckoutSession(
                sessionSetupResponse = sessionSetupResponse,
                order = order,
                environment = cardConfiguration.environment,
                clientKey = cardConfiguration.clientKey
            )
        cardComponent =
            createCardComponent(checkoutSession).apply {
                addComponent(this, componentId)
            }
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
                    componentCallback =
                        CardSessionCallback(
                            componentFlutterApi,
                            componentId,
                            ::onAction,
                            ::assignCurrentComponent
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            false -> {
                val paymentMethod = determineCardPaymentMethod(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    checkoutSession = checkoutSession,
                    paymentMethod = paymentMethod,
                    configuration = cardConfiguration,
                    componentCallback =
                        CardSessionCallback(
                            componentFlutterApi,
                            componentId,
                            ::onAction,
                            ::assignCurrentComponent,
                        ),
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
        adyenComponentView.layoutParams =
            ConstraintLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
    }

    private fun onAction(action: Action) = cardComponent?.handleAction(action, activity)

    private fun determineCardPaymentMethod(paymentMethodJson: JSONObject): PaymentMethod {
        return if (paymentMethodJson.length() > 0) {
            PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
        } else {
            val sessionResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
            sessionResponse.paymentMethodsApiResponse?.paymentMethods?.first { it.type == CARD_PAYMENT_METHOD_KEY }
                ?: throw Exception("Cannot find card payment method")
        }
    }
}
