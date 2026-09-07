package com.adyen.checkout.flutter.components.view

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.AdvancedCheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutController
import com.adyen.checkout.core.components.CheckoutPaymentFlow
import com.adyen.checkout.core.components.CheckoutTarget
import com.adyen.checkout.core.components.SessionCheckoutCallbacks
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethodResponse
import com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod
import com.adyen.checkout.flutter.components.CheckoutComponentRegistry
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutEventTypeDTO

internal class DynamicComponentView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0,
) : FrameLayout(context, attrs, defStyle) {
    private val screenDensity = resources.displayMetrics.density
    private var checkoutId = ""
    private var componentId = ""
    private var eventHandler: ComponentPlatformEventHandler? = null

    constructor(
        context: Context,
        checkoutId: String,
        componentId: String,
        eventHandler: ComponentPlatformEventHandler,
    ) : this(context) {
        this.checkoutId = checkoutId
        this.componentId = componentId
        this.eventHandler = eventHandler
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val heightSize = MeasureSpec.getSize(heightMeasureSpec)
        super.onMeasure(widthMeasureSpec, heightSize)
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        if (changed) {
            sendResize()
        }
    }

    fun addV6Component(
        activity: ComponentActivity,
        paymentMethod: PaymentMethodResponse,
        checkoutContext: CheckoutContext,
        callbacks: CheckoutCallbacks,
    ) {
        val target = when (paymentMethod) {
            is StoredPaymentMethod -> CheckoutTarget.StoredPaymentMethod(paymentMethod.id)
            else -> CheckoutTarget.PaymentMethod(paymentMethod.type.orEmpty())
        }

        addView(
            ComposeView(activity).apply {
                setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
                setContent {
                    val coroutineScope = rememberCoroutineScope()
                    val controller = remember(target, checkoutContext, callbacks) {
                        when {
                            checkoutContext is CheckoutContext.Advanced && callbacks is AdvancedCheckoutCallbacks ->
                                CheckoutController(
                                    target = target,
                                    context = checkoutContext,
                                    callbacks = callbacks,
                                    coroutineScope = coroutineScope,
                                )

                            checkoutContext is CheckoutContext.Sessions && callbacks is SessionCheckoutCallbacks ->
                                CheckoutController(
                                    target = target,
                                    context = checkoutContext,
                                    callbacks = callbacks,
                                    coroutineScope = coroutineScope,
                                )

                            else -> throw IllegalArgumentException(
                                "Invalid checkout context and callback combination.",
                            )
                        }
                    }

                    DisposableEffect(controller) {
                        CheckoutComponentRegistry.register(checkoutId, componentId, controller)
                        eventHandler?.send(
                            CheckoutEventDTO(
                                type = CheckoutEventTypeDTO.COMPONENT_READY,
                                checkoutId = checkoutId,
                                componentId = componentId,
                                requiresUserInteraction = controller.requiresUserInteraction(),
                            ),
                        )
                        onDispose {
                            CheckoutComponentRegistry.unregister(checkoutId, componentId)
                        }
                    }

                    CheckoutPaymentFlow(controller = controller)
                }
            },
        )
    }

    fun onDispose() {
        removeAllViews()
        eventHandler = null
    }

    private fun sendResize() {
        eventHandler?.send(
            CheckoutEventDTO(
                type = CheckoutEventTypeDTO.RESIZE,
                checkoutId = checkoutId,
                componentId = componentId,
                height = (measuredHeight / screenDensity).toLong(),
            ),
        )
    }
}
