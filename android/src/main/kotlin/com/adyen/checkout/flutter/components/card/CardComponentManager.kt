package com.adyen.checkout.flutter.components.card

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

internal class CardComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
    private val sessionHolder: SessionHolder?,
    private val onDispose: (String) -> Unit,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) {
    private var currentCardComponent: BaseCardComponent? = null

    fun registerComponentViewFactories() {
        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            CardComponentFactory.CARD_COMPONENT_ADVANCED,
            CardComponentFactory(
                activity,
                componentFlutterInterface,
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
                CardComponentFactory.CARD_COMPONENT_SESSION,
                onDispose,
                ::setCurrentCardComponent,
                sessionHolder,
            )
        )
    }

    fun updateViewHeight() {
        activity.lifecycleScope.launch {
            // This delay is necessary to prevent an initial UI flickering due to the delayed rendering of the scheme icons.
            delay(300)
            currentCardComponent?.resizeFlutterViewPort()
        }
    }

    private fun setCurrentCardComponent(currentCardComponent: BaseCardComponent) {
        this.currentCardComponent = currentCardComponent
        assignCurrentComponent(currentCardComponent.cardComponent)
    }
}
