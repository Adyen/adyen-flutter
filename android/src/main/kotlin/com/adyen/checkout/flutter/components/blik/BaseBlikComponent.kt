package com.adyen.checkout.flutter.components.blik

import android.content.Context
import android.view.View
import androidx.activity.ComponentActivity
import com.adyen.checkout.blik.BlikComponent
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import com.adyen.checkout.flutter.generated.BlikComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import io.flutter.plugin.platform.PlatformView

abstract class BaseBlikComponent(
    private val creationParams: Map<*, *>,
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentBlikComponent: (BaseBlikComponent) -> Unit,
) : PlatformView {
    private val configuration =
        creationParams[BLIK_COMPONENT_CONFIGURATION_KEY] as BlikComponentConfigurationDTO?
            ?: throw Exception("Blik configuration not found")
    internal val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
    internal val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""
    private val dynamicComponentView = DynamicComponentView(activity, componentFlutterApi, componentId)
    internal val checkoutConfiguration = configuration.toCheckoutConfiguration()
    internal var blikComponent: BlikComponent? = null

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

    companion object {
        const val BLIK_COMPONENT_CONFIGURATION_KEY = "blikComponentConfiguration"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val COMPONENT_ID_KEY = "componentId"
    }
}
