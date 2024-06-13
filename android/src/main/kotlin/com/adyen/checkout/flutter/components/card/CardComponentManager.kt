package com.adyen.checkout.flutter.components.card

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class CardComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding?,
    private val sessionHolder: SessionHolder?,
) {
    private var currentCardComponent: BaseCardComponent? = null

    fun registerComponentViewFactories() {
        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            CardComponentFactory.CARD_COMPONENT_ADVANCED,
            CardComponentFactory(
                activity,
                componentFlutterInterface,
                CardComponentFactory.CARD_COMPONENT_ADVANCED,
                null,
                ::setCurrentCardComponent
            )
        )

        flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
            CardComponentFactory.CARD_COMPONENT_SESSION,
            CardComponentFactory(
                activity,
                componentFlutterInterface,
                CardComponentFactory.CARD_COMPONENT_SESSION,
                sessionHolder,
                ::setCurrentCardComponent
            )
        )
    }

    fun updateViewHeight() {
        activity.lifecycleScope.launch {
            delay(300)
            currentCardComponent?.resizeFlutterViewPort()
        }
    }

    private fun setCurrentCardComponent(currentCardComponent: BaseCardComponent) {
        this.currentCardComponent = currentCardComponent
    }
}
