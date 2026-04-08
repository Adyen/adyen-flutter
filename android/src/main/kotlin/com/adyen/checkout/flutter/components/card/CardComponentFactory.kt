package com.adyen.checkout.flutter.components.card

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class CardComponentFactory(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentEventHandler: ComponentPlatformEventHandler,
    private val viewTypeId: String,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseCardComponent) -> Unit,
    private val checkoutHolder: CheckoutHolder? = null,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    companion object {
        const val CARD_COMPONENT_ADVANCED = "cardComponentAdvanced"
        const val CARD_COMPONENT_SESSION = "cardComponentSession"
    }

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        val cardComponent =
            if (viewTypeId == CARD_COMPONENT_SESSION && checkoutHolder != null) {
                CardSessionComponent(
                    creationParams,
                    activity,
                    componentFlutterApi,
                    componentEventHandler,
                    onDispose,
                    setCurrentCardComponent,
                    checkoutHolder
                )
            } else {
                CardAdvancedComponent(
                    creationParams,
                    activity,
                    componentFlutterApi,
                    componentEventHandler,
                    onDispose,
                    setCurrentCardComponent
                )
            }
        setCurrentCardComponent(cardComponent)
        return cardComponent
    }
}
