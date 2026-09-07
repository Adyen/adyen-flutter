package com.adyen.checkout.flutter.session

import com.adyen.checkout.core.common.CheckoutContext

internal class CheckoutHolder {
    private val contexts = mutableMapOf<String, CheckoutContext>()
    private var activeActionId: String? = null

    @Synchronized
    fun isActive(): Boolean = contexts.isNotEmpty() || activeActionId != null

    @Synchronized
    fun put(checkoutId: String, context: CheckoutContext) {
        contexts[checkoutId] = context
    }

    @Synchronized
    fun get(checkoutId: String): CheckoutContext? = contexts[checkoutId]

    @Synchronized
    fun remove(checkoutId: String) {
        contexts.remove(checkoutId)
    }

    @Synchronized
    fun beginAction(actionId: String): Boolean {
        if (isActive()) return false
        activeActionId = actionId
        return true
    }

    @Synchronized
    fun endAction(actionId: String) {
        if (activeActionId == actionId) activeActionId = null
    }

    @Synchronized
    fun clear() {
        contexts.clear()
        activeActionId = null
    }
}
