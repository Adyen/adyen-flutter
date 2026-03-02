package com.adyen.checkout.flutter.components.blik

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin

internal class BlikComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
    private val sessionHolder: SessionHolder?,
    private val onDispose: (String) -> Unit,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) {
    private var currentBlikComponent: BaseBlikComponent? = null

    fun registerComponentViewFactories() {
        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            BlikComponentFactory.BLIK_COMPONENT_ADVANCED,
            BlikComponentFactory(
                activity,
                componentFlutterInterface,
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
                BlikComponentFactory.BLIK_COMPONENT_SESSION,
                onDispose,
                ::setCurrentBlikComponent,
                sessionHolder,
            ),
        )
    }

    private fun setCurrentBlikComponent(currentBlikComponent: BaseBlikComponent) {
        this.currentBlikComponent = currentBlikComponent
        assignCurrentComponent(currentBlikComponent.blikComponent)
    }
}
