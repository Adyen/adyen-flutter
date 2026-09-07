package com.adyen.checkout.flutter.components

import android.content.Context
import android.view.View
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethodResponse
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import io.flutter.plugin.platform.PlatformView

internal class CheckoutPaymentView(
    activity: FragmentActivity,
    context: Context,
    private val checkoutId: String,
    private val componentId: String,
    paymentMethod: PaymentMethodResponse,
    checkoutContext: CheckoutContext,
    callbacks: CheckoutCallbacks,
    eventHandler: ComponentPlatformEventHandler,
) : PlatformView {
    private val dynamicComponentView = DynamicComponentView(
        context = context,
        checkoutId = checkoutId,
        componentId = componentId,
        eventHandler = eventHandler,
    )

    init {
        dynamicComponentView.addV6Component(
            activity = activity,
            paymentMethod = paymentMethod,
            checkoutContext = checkoutContext,
            callbacks = callbacks,
        )
    }

    override fun getView(): View = dynamicComponentView

    override fun dispose() {
        dynamicComponentView.onDispose()
        CheckoutComponentRegistry.unregister(checkoutId, componentId)
    }
}
