package com.adyen.checkout.flutter.components.v2

import android.content.Context
import android.view.View
import androidx.activity.ComponentActivity
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethod
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import io.flutter.plugin.platform.PlatformView

internal class AdyenComponent(
    checkoutContext: CheckoutContext,
    checkoutCallbacks: CheckoutCallbacks,
    paymentMethod: PaymentMethod,
    context: Context,
    private val componentId: String,
    private val onDispose: (String) -> Unit,
    platformEventHandler: ComponentPlatformEventHandler,
) : PlatformView {
    internal val dynamicComponentView = DynamicComponentView(context, componentId, platformEventHandler)

    init {
        dynamicComponentView.addV6Component(
            paymentMethod = paymentMethod,
            checkoutContext = checkoutContext,
            callbacks = checkoutCallbacks
        )
    }

    override fun getView(): View = dynamicComponentView

    override fun dispose() {
        dynamicComponentView.onDispose()
        onDispose(componentId)
    }
}
