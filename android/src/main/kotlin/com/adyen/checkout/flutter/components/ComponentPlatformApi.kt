package com.adyen.checkout.flutter.components

import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.ComponentHostApi
import com.adyen.checkout.flutter.generated.EventsStreamHandler
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin

internal class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val checkoutHolder: CheckoutHolder,
    callbacksApi: CheckoutCallbacksFlutterApi,
    private val eventHandler: ComponentPlatformEventHandler,
    flutterPluginBinding: FlutterPlugin.FlutterPluginBinding,
) : ComponentHostApi {
    init {
        EventsStreamHandler.register(flutterPluginBinding.binaryMessenger, eventHandler)
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            CheckoutPaymentViewFactory(
                activity = activity,
                checkoutHolder = checkoutHolder,
                callbacksApi = callbacksApi,
                eventHandler = eventHandler,
            ),
        )
    }

    override fun submit(
        checkoutId: String,
        componentId: String,
        callback: (Result<Unit>) -> Unit,
    ) {
        try {
            if (!CheckoutComponentRegistry.submit(checkoutId, componentId)) {
                throw AdyenPigeonError(
                    "ComponentNotFound",
                    "Checkout component is no longer active.",
                )
            }
            callback(Result.success(Unit))
        } catch (error: Throwable) {
            callback(Result.failure(error))
        }
    }

    override fun dispose(checkoutId: String, componentId: String) {
        CheckoutComponentRegistry.unregister(checkoutId, componentId)
    }

    fun handleReturn(intent: Intent) {
        CheckoutComponentRegistry.handleReturn(intent)
    }

    fun teardown() {
        CheckoutComponentRegistry.clear()
    }

    companion object {
        const val VIEW_TYPE = "AdyenCheckoutPaymentComponent"
    }
}
