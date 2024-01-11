package com.adyen.checkout.flutter.components.card

import ComponentFlutterInterface
import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.flutter.components.card.advanced.CardAdvancedComponent
import com.adyen.checkout.flutter.components.card.session.CardSessionComponent
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class CardComponentFactory(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val viewTypeId: String,
    private val sessionHolder: SessionHolder? = null,
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
        return if (viewTypeId == CARD_COMPONENT_SESSION && sessionHolder != null) {
            CardSessionComponent(activity, componentFlutterApi, sessionHolder, context, viewId, creationParams)
        } else {
            CardAdvancedComponent(activity, componentFlutterApi, context, viewId, creationParams)
        }
    }
}
