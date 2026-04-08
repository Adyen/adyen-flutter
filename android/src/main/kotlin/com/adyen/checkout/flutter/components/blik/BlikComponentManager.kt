package com.adyen.checkout.flutter.components.blik

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin

internal class BlikComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val componentEventHandler: ComponentPlatformEventHandler,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
    private val checkoutHolder: CheckoutHolder?,
    private val onDispose: (String) -> Unit,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) {
    fun registerComponentViewFactories() {
        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            BlikComponentFactory.BLIK_COMPONENT_ADVANCED,
            BlikComponentFactory(
                activity,
                componentFlutterInterface,
                componentEventHandler,
                BlikComponentFactory.BLIK_COMPONENT_ADVANCED,
                onDispose,
                ::setCurrentBlikComponent,
                null,
            ),
        )

        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            BlikComponentFactory.BLIK_COMPONENT_SESSION,
            BlikComponentFactory(
                activity,
                componentFlutterInterface,
                componentEventHandler,
                BlikComponentFactory.BLIK_COMPONENT_SESSION,
                onDispose,
                ::setCurrentBlikComponent,
                checkoutHolder,
            ),
        )
    }

    private fun setCurrentBlikComponent(currentBlikComponent: BaseBlikComponent) {
        assignCurrentComponent(currentBlikComponent.blikComponent)
    }
}
