package com.adyen.checkout.flutter.components.view

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.lifecycle.SavedStateHandle
import com.adyen.checkout.core.action.data.ActionData
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.AdvancedCheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutAction
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutController
import com.adyen.checkout.core.components.CheckoutPaymentMethod
import com.adyen.checkout.core.components.CheckoutTarget
import com.adyen.checkout.core.components.SessionCheckoutCallbacks
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethodResponse
import com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod
import com.adyen.checkout.flutter.components.CheckoutComponentRegistry
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutEventTypeDTO
import kotlin.math.ceil

internal class DynamicComponentView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0,
) : FrameLayout(context, attrs, defStyle) {
    private val screenDensity = resources.displayMetrics.density
    private var checkoutId = ""
    private var componentId = ""
    private var eventHandler: ComponentPlatformEventHandler? = null
    private var composeView: ComposeView? = null
    private var registry: CheckoutComponentRegistry? = null
    private var lastReportedHeight: Long = -1

    constructor(
        context: Context,
        checkoutId: String,
        componentId: String,
        eventHandler: ComponentPlatformEventHandler,
        registry: CheckoutComponentRegistry,
    ) : this(context) {
        this.checkoutId = checkoutId
        this.componentId = componentId
        this.eventHandler = eventHandler
        this.registry = registry
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED))
        val height = ceil(measuredHeight / screenDensity).toLong()
        if (height > 0 && height != lastReportedHeight) {
            lastReportedHeight = height
            post { sendResize(height) }
        }
    }

    fun addV6Component(
        activity: ComponentActivity,
        paymentMethod: PaymentMethodResponse,
        checkoutContext: CheckoutContext,
        callbacks: CheckoutCallbacks,
        actionData: MutableState<ActionData?>,
    ) {
        val target = when (paymentMethod) {
            is StoredPaymentMethod -> CheckoutTarget.StoredPaymentMethod(paymentMethod.id)
            else -> CheckoutTarget.PaymentMethod(paymentMethod.type.orEmpty())
        }

        val view =
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
                                    savedStateHandle = SavedStateHandle(),
                                )

                            checkoutContext is CheckoutContext.Sessions && callbacks is SessionCheckoutCallbacks ->
                                CheckoutController(
                                    target = target,
                                    context = checkoutContext,
                                    callbacks = callbacks,
                                    coroutineScope = coroutineScope,
                                    savedStateHandle = SavedStateHandle(),
                                )

                            else -> throw IllegalArgumentException(
                                "Invalid checkout context and callback combination.",
                            )
                        }
                    }

                    DisposableEffect(controller) {
                        registry?.register(checkoutId, componentId, controller)
                        eventHandler?.send(
                            CheckoutEventDTO(
                                type = CheckoutEventTypeDTO.COMPONENT_READY,
                                checkoutId = checkoutId,
                                componentId = componentId,
                                requiresUserInteraction = controller.requiresUserInteraction(),
                            ),
                        )
                        onDispose {
                            registry?.unregister(checkoutId, componentId)
                        }
                    }

                    if (actionData.value != null) {
                        CheckoutAction(controller = controller)
                    } else {
                        CheckoutPaymentMethod(controller = controller)
                    }
                }
            }
        composeView = view
        addView(view)
    }

    fun onDispose() {
        composeView?.disposeComposition()
        composeView = null
        removeAllViews()
        eventHandler = null
    }

    private fun sendResize(height: Long) {
        eventHandler?.send(
            CheckoutEventDTO(
                type = CheckoutEventTypeDTO.RESIZE,
                checkoutId = checkoutId,
                componentId = componentId,
                height = height,
            ),
        )
    }
}
