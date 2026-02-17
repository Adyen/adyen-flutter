package com.adyen.checkout.flutter.components.v2

import android.content.Context
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.old.CardComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.core.common.PaymentResult
import com.adyen.checkout.core.components.AdyenPaymentFlow
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.flutter.components.card.BaseCardComponent
import com.adyen.checkout.flutter.components.card.session.CardSessionCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.PlatformException
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import org.json.JSONObject
import java.util.UUID

internal class AdyenSessionComponent(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseComponent) -> Unit,
    private val sessionHolder: SessionHolder
) : BaseComponent(context, id, creationParams, activity, componentFlutterApi, onDispose, setCurrentCardComponent) {
    init {
        val sessionCheckout = sessionHolder.sessionCheckout ?: throw PlatformException("Session not initialized")
        val paymentMethod = com.adyen.checkout.core.components.data.model.PaymentMethod.SERIALIZER.deserialize(
            JSONObject(paymentMethodString)
        )
        val checkoutCallbacks = CheckoutCallbacks(
            onError = {
                println("ON ERROR INVOKED")
            },
            onFinished = { it: PaymentResult ->
                println("ON FINISHED INVOKED: ${it.sessionResult}")
            }
        )

        addV6Component(
            paymentMethod = paymentMethod,
            checkoutContext = sessionCheckout,
            callbacks = checkoutCallbacks
        )
    }
}
