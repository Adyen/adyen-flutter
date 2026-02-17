package com.adyen.checkout.flutter.components.v2

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.flutter.components.card.BaseCardComponent
import com.adyen.checkout.flutter.components.card.advanced.CardAdvancedComponent
import com.adyen.checkout.flutter.components.card.session.CardSessionComponent
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class AdyenComponentFactory(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val viewTypeId: String,
    private val onDispose: (String) -> Unit,
    private val setCurrentComponent: (BaseComponent) -> Unit,
    private val sessionHolder: SessionHolder? = null,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    companion object {
        const val ADYEN_COMPONENT_ADVANCED = "AdyenAdvancedComponent"
        const val ADYEN_COMPONENT_SESSION = "AdyenSessionComponent"
    }

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        val component =
            if (viewTypeId == ADYEN_COMPONENT_SESSION && sessionHolder != null) {
                AdyenSessionComponent(
                    context,
                    viewId,
                    creationParams,
                    activity,
                    componentFlutterApi,
                    onDispose,
                    setCurrentComponent,
                    sessionHolder
                )
            } else {
                AdyenAdvancedComponent(
                    context,
                    viewId,
                    creationParams,
                    activity,
                    componentFlutterApi,
                    onDispose,
                    setCurrentComponent
                )
            }
        setCurrentComponent(component)
        return component
    }
}
