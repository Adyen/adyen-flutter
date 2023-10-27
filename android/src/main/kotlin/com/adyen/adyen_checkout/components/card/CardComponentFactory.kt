package com.adyen.adyen_checkout.components.card

import ComponentFlutterApi
import android.content.Context
import androidx.activity.ComponentActivity
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class CardComponentFactory(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
) : PlatformViewFactory(ComponentFlutterApi.codec) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<*, *>?
        return CardComponent(activity, componentFlutterApi, context, viewId, creationParams)
    }
}
