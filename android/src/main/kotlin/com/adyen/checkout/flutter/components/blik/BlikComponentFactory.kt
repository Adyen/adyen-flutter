package com.adyen.checkout.flutter.components.blik

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.flutter.components.blik.advanced.BlikAdvancedComponent
import com.adyen.checkout.flutter.components.blik.session.BlikSessionComponent
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class BlikComponentFactory(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val viewTypeId: String,
    private val onDispose: (String) -> Unit,
    private val setCurrentBlikComponent: (BaseBlikComponent) -> Unit,
    private val sessionHolder: SessionHolder? = null,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    companion object {
        const val BLIK_COMPONENT_ADVANCED = "blikComponentAdvanced"
        const val BLIK_COMPONENT_SESSION = "blikComponentSession"
    }

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        val blikComponent =
            if (viewTypeId == BLIK_COMPONENT_SESSION && sessionHolder != null) {
                BlikSessionComponent(
                    creationParams,
                    activity,
                    componentFlutterApi,
                    onDispose,
                    setCurrentBlikComponent,
                    sessionHolder,
                )
            } else {
                BlikAdvancedComponent(
                    creationParams,
                    activity,
                    componentFlutterApi,
                    onDispose,
                    setCurrentBlikComponent,
                )
            }
        setCurrentBlikComponent(blikComponent)
        return blikComponent
    }
}
