package com.adyen.checkout.flutter.components.card

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin

internal class CardComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val componentEventHandler: ComponentPlatformEventHandler,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
    private val checkoutHolder: CheckoutHolder,
    private val onDispose: (String) -> Unit,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) {
    fun registerComponentViewFactories() {
        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            CardComponentFactory.CARD_COMPONENT_ADVANCED,
            CardComponentFactory(
                activity,
                componentFlutterInterface,
                componentEventHandler,
                CardComponentFactory.CARD_COMPONENT_ADVANCED,
                onDispose,
                ::setCurrentCardComponent,
                null,
            )
        )

        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            CardComponentFactory.CARD_COMPONENT_SESSION,
            CardComponentFactory(
                activity,
                componentFlutterInterface,
                componentEventHandler,
                CardComponentFactory.CARD_COMPONENT_SESSION,
                onDispose,
                ::setCurrentCardComponent,
                checkoutHolder,
            )
        )
    }

    private fun setCurrentCardComponent(currentCardComponent: BaseCardComponent) {
        assignCurrentComponent(currentCardComponent.cardComponent)
    }
}
