package com.adyen.checkout.flutter.components

import android.content.Intent
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.ComponentHostApi
import com.adyen.checkout.flutter.utils.ErrorCodes

internal class ComponentPlatformApi(
    private val registry: CheckoutComponentRegistry,
) : ComponentHostApi {
    override fun submit(
        checkoutId: String,
        componentId: String,
        callback: (Result<Unit>) -> Unit,
    ) {
        try {
            if (!registry.submit(checkoutId, componentId)) {
                throw AdyenPigeonError(
                    ErrorCodes.COMPONENT_NOT_FOUND,
                    "Checkout component is no longer active.",
                )
            }
            callback(Result.success(Unit))
        } catch (error: Throwable) {
            callback(Result.failure(error))
        }
    }

    override fun dispose(checkoutId: String, componentId: String) {
        registry.unregister(checkoutId, componentId)
    }

    fun handleReturn(intent: Intent) {
        registry.handleReturn(intent)
    }

    fun teardown() {
        registry.clear()
    }

    companion object {
        const val VIEW_TYPE = "AdyenCheckoutPaymentComponent"
    }
}
