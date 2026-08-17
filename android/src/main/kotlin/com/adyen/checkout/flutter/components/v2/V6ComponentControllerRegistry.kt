package com.adyen.checkout.flutter.components.v2

import android.content.Intent
import com.adyen.checkout.core.components.CheckoutController

internal data class V6ComponentControllerHandle(
    val submit: () -> Unit,
    val handleReturn: (Intent) -> Unit,
    val requiresUserInteraction: () -> Boolean,
)

internal object V6ComponentControllerRegistry {

    private val controllers = mutableMapOf<String, V6ComponentControllerHandle>()
    private var activeComponentId: String? = null

    fun register(
        componentId: String,
        controller: CheckoutController,
    ) {
        controllers[componentId] = V6ComponentControllerHandle(
            submit = { controller.submit() },
            handleReturn = { controller.handleReturn(it) },
            requiresUserInteraction = { controller.requiresUserInteraction() },
        )
    }

    fun unregister(componentId: String) {
        controllers.remove(componentId)
        if (activeComponentId == componentId) {
            activeComponentId = null
        }
    }

    fun getHandle(componentId: String): V6ComponentControllerHandle? = controllers[componentId]

    fun setActive(componentId: String) {
        if (controllers.containsKey(componentId)) {
            activeComponentId = componentId
        }
    }

    fun getActiveHandle(): V6ComponentControllerHandle? = activeComponentId?.let { controllers[it] }

    fun getActiveComponentId(): String? = activeComponentId

    fun clear() {
        controllers.clear()
        activeComponentId = null
    }

    fun isEmpty(): Boolean = controllers.isEmpty()
}
