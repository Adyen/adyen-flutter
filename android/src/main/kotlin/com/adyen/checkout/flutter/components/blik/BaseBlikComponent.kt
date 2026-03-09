package com.adyen.checkout.flutter.components.blik

import android.view.View
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.blik.BlikComponent
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import com.adyen.checkout.flutter.generated.BlikComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import io.flutter.plugin.platform.PlatformView

abstract class BaseBlikComponent(
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentBlikComponent: (BaseBlikComponent) -> Unit,
) : PlatformView {
    internal var blikComponent: BlikComponent? = null
    internal val checkoutConfiguration =
        (creationParams[Constants.BLIK_COMPONENT_CONFIGURATION_KEY] as BlikComponentConfigurationDTO?)
            ?.toCheckoutConfiguration()
            ?: throw IllegalArgumentException("Blik configuration not found")
    internal val paymentMethodString = creationParams[Constants.PAYMENT_METHOD_KEY] as String? ?: ""
    internal val componentId = creationParams[Constants.COMPONENT_ID_KEY] as String? ?: ""
    private val dynamicComponentView = DynamicComponentView(activity, componentFlutterApi, componentId)

    override fun getView(): View = dynamicComponentView

    override fun dispose() {
        dynamicComponentView.onDispose()
        blikComponent = null
        onDispose(componentId)
    }

    fun addComponent(blikComponent: BlikComponent) {
        dynamicComponentView.addComponent(blikComponent, activity)
    }

    fun setCurrentBlikComponent() = setCurrentBlikComponent(this)
}
