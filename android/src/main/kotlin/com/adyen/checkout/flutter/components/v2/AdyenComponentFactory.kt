package com.adyen.checkout.flutter.components.v2

import android.content.Context
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class AdyenComponentFactory(
    private val componentFlutterApi: ComponentFlutterInterface,
    private val adyenFlutterInterface: AdyenFlutterInterface,
    private val viewTypeId: String,
    private val onDispose: (String) -> Unit,
    private val checkoutHolder: CheckoutHolder,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    companion object {
        const val ADYEN_COMPONENT_ADVANCED = "AdyenAdvancedComponent"
        const val ADYEN_COMPONENT_SESSION = "AdyenSessionComponent"
    }

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        return if (viewTypeId == ADYEN_COMPONENT_SESSION) {
            AdyenSessionComponent(
                checkoutHolder = checkoutHolder,
                context = context,
                creationParams = creationParams,
                componentFlutterApi = componentFlutterApi,
                adyenFlutterInterface = adyenFlutterInterface,
                onDispose = onDispose,
            )
        } else {
            AdyenAdvancedComponent(
                checkoutHolder = checkoutHolder,
                context = context,
                creationParams = creationParams,
                componentFlutterApi = componentFlutterApi,
                adyenFlutterInterface = adyenFlutterInterface,
                onDispose = onDispose,
            )
        }
    }
}
