package com.adyen.checkout.flutter.components.card.session

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.old.CardComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.card.BaseCardComponent
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import org.json.JSONObject
import java.util.UUID

internal class CardSessionComponent(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseCardComponent) -> Unit,
    private val checkoutHolder: CheckoutHolder
) : BaseCardComponent(context, id, creationParams, activity, componentFlutterApi, onDispose, setCurrentCardComponent) {
    init {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(checkoutHolder.sessionSetupResponse)
        val checkoutSession =
            CheckoutSession(
                sessionSetupResponse = sessionSetupResponse,
                order = null,
                environment = checkoutConfiguration.environment,
                clientKey = checkoutConfiguration.clientKey
            )
        cardComponent =
            createCardComponent(checkoutSession).apply {
                addComponent(this)
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
                    checkoutConfiguration = checkoutConfiguration,
                    componentCallback =
                        CardSessionCallback(
                            componentFlutterApi,
                            componentId,
                            ::onAction,
                            ::setCurrentCardComponent,
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
                    checkoutConfiguration = checkoutConfiguration,
                    componentCallback =
                        CardSessionCallback(
                            componentFlutterApi,
                            componentId,
                            ::onAction,
                            ::setCurrentCardComponent,
                        ),
                    key = UUID.randomUUID().toString()
                )
            }
        }
    }

    private fun onAction(action: Action) = cardComponent?.handleAction(action, activity)

    private fun determineCardPaymentMethod(paymentMethodJson: JSONObject): PaymentMethod =
        if (paymentMethodJson.length() > 0) {
            PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
        } else {
            val sessionResponse = SessionSetupResponse.SERIALIZER.deserialize(checkoutHolder.sessionSetupResponse)
            sessionResponse.paymentMethodsApiResponse?.paymentMethods?.first { it.type == CARD_PAYMENT_METHOD_KEY }
                ?: throw Exception("Cannot find card payment method")
        }
}
