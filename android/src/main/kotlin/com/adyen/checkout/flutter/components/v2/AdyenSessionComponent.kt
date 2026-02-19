package com.adyen.checkout.flutter.components.v2

import android.content.Context
import com.adyen.checkout.core.common.PaymentResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.PlatformException
import org.json.JSONObject

internal class AdyenSessionComponent(
    checkoutHolder: CheckoutHolder,
    private val context: Context,
    private val creationParams: Map<*, *>,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val adyenFlutterInterface: AdyenFlutterInterface,
    private val onDispose: (String) -> Unit,
) : BaseComponent(
    checkoutHolder,
    context,
    creationParams,
    componentFlutterApi,
    adyenFlutterInterface,
    onDispose,
) {
    init {
        val sessionCheckout = checkoutHolder.checkoutContext ?: throw PlatformException("Session not initialized")
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

        dynamicComponentView.addV6Component(
            paymentMethod = paymentMethod,
            checkoutContext = sessionCheckout,
            callbacks = checkoutCallbacks
        )
    }
}
