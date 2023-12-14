package com.adyen.adyen_checkout.components.card.session

import ComponentFlutterInterface
import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.adyen_checkout.session.SessionHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class CardSessionComponentFactory(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val sessionHolder: SessionHolder,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        return CardSessionComponent(activity, componentFlutterApi, sessionHolder, context, viewId, creationParams)
    }
}
