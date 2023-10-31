package com.adyen.adyen_checkout.components.card.session

import ComponentFlutterApi
import android.content.Context
import androidx.activity.ComponentActivity
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class CardSessionFlowComponentFactory(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
) : PlatformViewFactory(ComponentFlutterApi.codec) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<*, *>?
        return CardSessionFlowComponent(activity, componentFlutterApi, context, viewId, creationParams)
    }
}
