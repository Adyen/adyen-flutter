package com.adyen.checkout.flutter.components

import android.content.Context
import androidx.fragment.app.FragmentActivity
import androidx.compose.runtime.mutableStateOf
import com.adyen.checkout.core.action.data.ActionData
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethod
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethodResponse
import com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutPaymentViewParamsDTO
import com.adyen.checkout.flutter.generated.ComponentHostApi
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject

internal class CheckoutPaymentViewFactory(
    private val activityProvider: () -> FragmentActivity?,
    private val checkoutHolder: CheckoutHolder,
    callbacksApi: CheckoutCallbacksFlutterApi,
    private val eventHandler: ComponentPlatformEventHandler,
    private val registry: CheckoutComponentRegistry,
) : PlatformViewFactory(ComponentHostApi.codec) {
    private val callbacksBridge = CheckoutCallbacksBridge(callbacksApi, eventHandler, registry)

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView {
        val params = args as? CheckoutPaymentViewParamsDTO
        try {
            if (params == null) throw IllegalArgumentException("Invalid platform view params.")
            val activity = activityProvider() ?: throw IllegalStateException("No FragmentActivity attached.")
            val checkoutContext = checkoutHolder.get(params.checkoutId)
                ?: throw AdyenPigeonError("CheckoutNotFound", "Checkout is no longer active.")
            val paymentMethod = deserializePaymentMethod(params.paymentMethodJson, params.isStoredPaymentMethod)
            val actionData = mutableStateOf<ActionData?>(null)
            val callbacks = callbacksBridge.createCallbacks(params.checkoutId, params.componentId, checkoutContext) {
                actionData.value = it
            }

            return CheckoutPaymentView(
                activity = activity,
                context = context,
                checkoutId = params.checkoutId,
                componentId = params.componentId,
                paymentMethod = paymentMethod,
                checkoutContext = checkoutContext,
                callbacks = callbacks,
                actionData = actionData,
                eventHandler = eventHandler,
                registry = registry,
            )
        } catch (error: Throwable) {
            return FailedCheckoutPaymentView(context, params?.checkoutId, params?.componentId, eventHandler, error)
        }
    }

    private fun deserializePaymentMethod(
        json: String,
        isStoredPaymentMethod: Boolean,
    ): PaymentMethodResponse {
        val jsonObject = JSONObject(json)
        return if (isStoredPaymentMethod) {
            StoredPaymentMethod.SERIALIZER.deserialize(jsonObject)
        } else {
            PaymentMethod.SERIALIZER.deserialize(jsonObject)
        }
    }
}
