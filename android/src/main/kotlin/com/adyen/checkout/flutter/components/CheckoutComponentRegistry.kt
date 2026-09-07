package com.adyen.checkout.flutter.components

import android.content.Intent
import com.adyen.checkout.core.components.CheckoutController

internal object CheckoutComponentRegistry {
    private data class Handle(
        val checkoutId: String,
        val submit: () -> Unit,
        val handleReturn: (Intent) -> Unit,
        val requiresUserInteraction: () -> Boolean,
    )

    private val components = mutableMapOf<String, Handle>()
    private var activeComponentId: String? = null

    @Synchronized
    fun register(checkoutId: String, componentId: String, controller: CheckoutController) {
        components[componentId] = Handle(
            checkoutId = checkoutId,
            submit = controller::submit,
            handleReturn = controller::handleReturn,
            requiresUserInteraction = controller::requiresUserInteraction,
        )
    }

    @Synchronized
    fun unregister(checkoutId: String, componentId: String) {
        if (components[componentId]?.checkoutId == checkoutId) {
            components.remove(componentId)
            if (activeComponentId == componentId) activeComponentId = null
        }
    }

    @Synchronized
    fun submit(checkoutId: String, componentId: String): Boolean {
        val handle = components[componentId]
        if (handle?.checkoutId != checkoutId) return false
        activeComponentId = componentId
        handle.submit()
        return true
    }

    @Synchronized
    fun requiresUserInteraction(checkoutId: String, componentId: String): Boolean? {
        val handle = components[componentId]
        return if (handle?.checkoutId == checkoutId) handle.requiresUserInteraction() else null
    }

    @Synchronized
    fun handleReturn(intent: Intent) {
        activeComponentId?.let { components[it]?.handleReturn?.invoke(intent) }
    }

    @Synchronized
    fun clearCheckout(checkoutId: String) {
        components.entries.removeIf { it.value.checkoutId == checkoutId }
        if (activeComponentId != null && components[activeComponentId] == null) {
            activeComponentId = null
        }
    }

    @Synchronized
    fun clear() {
        components.clear()
        activeComponentId = null
    }
}
