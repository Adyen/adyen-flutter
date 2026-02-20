package com.adyen.checkout.flutter.components.v2

import androidx.activity.ComponentActivity
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.data.model.PaymentMethod
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler

internal class AdyenComponent(
    checkoutContext: CheckoutContext,
    checkoutCallbacks: CheckoutCallbacks,
    paymentMethod: PaymentMethod,
    activity: ComponentActivity,
    creationParams: Map<*, *>,
    private val onDispose: (String) -> Unit,
    private val platformEventHandler: ComponentPlatformEventHandler,
) : BaseComponent(
    activity,
    creationParams,
    onDispose,
    platformEventHandler,
) {
    init {
        dynamicComponentView.addV6Component(
            paymentMethod = paymentMethod,
            checkoutContext = checkoutContext,
            callbacks = checkoutCallbacks
        )
    }
}
