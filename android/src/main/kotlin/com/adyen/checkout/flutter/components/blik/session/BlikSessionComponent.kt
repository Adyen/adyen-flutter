package com.adyen.checkout.flutter.components.blik.session

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.blik.BlikComponent
import com.adyen.checkout.blik.BlikComponentState
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.base.ComponentSessionCallback
import com.adyen.checkout.flutter.components.blik.BaseBlikComponent
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.session.toCheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSession
import org.json.JSONObject
import java.util.UUID

internal class BlikSessionComponent(
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentBlikComponent: (BaseBlikComponent) -> Unit,
    private val sessionHolder: SessionHolder,
) : BaseBlikComponent(
        creationParams,
        activity,
        componentFlutterApi,
        onDispose,
        setCurrentBlikComponent,
    ) {
    init {
        val checkoutSession = sessionHolder.toCheckoutSession(checkoutConfiguration.environment, checkoutConfiguration.clientKey)

        blikComponent =
            createBlikComponent(checkoutSession).apply {
                addComponent(this)
            }
    }

    private fun createBlikComponent(checkoutSession: CheckoutSession): BlikComponent {
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(JSONObject(paymentMethodString))
        return BlikComponent.PROVIDER.get(
            activity = activity,
            checkoutSession = checkoutSession,
            paymentMethod = paymentMethod,
            checkoutConfiguration = checkoutConfiguration,
            componentCallback =
                ComponentSessionCallback<BlikComponentState>(
                    componentFlutterApi,
                    componentId,
                    ::onAction,
                    ::setCurrentBlikComponent,
                ),
            key = UUID.randomUUID().toString(),
        )
    }

    private fun onAction(action: Action) = blikComponent?.handleAction(action, activity)
}
