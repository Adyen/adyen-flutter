package com.adyen.checkout.flutter.session

import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.flutter.generated.CardCallbacksDTO

internal class CheckoutHolder {
    private val contexts = mutableMapOf<String, CheckoutContext>()
    private val cardCallbacks = mutableMapOf<String, CardCallbacksDTO>()
    private var activeActionId: String? = null

    @Synchronized
    fun isActive(): Boolean = contexts.isNotEmpty() || activeActionId != null

    @Synchronized
    fun put(checkoutId: String, context: CheckoutContext, cardCallbacks: CardCallbacksDTO? = null) {
        contexts[checkoutId] = context
        if (cardCallbacks != null) {
            this.cardCallbacks[checkoutId] = cardCallbacks
        } else {
            this.cardCallbacks.remove(checkoutId)
        }
    }

    @Synchronized
    fun get(checkoutId: String): CheckoutContext? = contexts[checkoutId]

    @Synchronized
    fun getCardCallbacks(checkoutId: String): CardCallbacksDTO? = cardCallbacks[checkoutId]

    @Synchronized
    fun remove(checkoutId: String) {
        contexts.remove(checkoutId)
        cardCallbacks.remove(checkoutId)
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
        cardCallbacks.clear()
        activeActionId = null
    }
}
