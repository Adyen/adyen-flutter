package com.adyen.checkout.flutter.components.card

import CardComponentConfigurationDTO
import ComponentFlutterInterface
import android.content.Context
import android.view.View
import androidx.activity.ComponentActivity
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAmount
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCardConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import io.flutter.plugin.platform.PlatformView

abstract class BaseCardComponent(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<*, *>,
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseCardComponent) -> Unit,
) : PlatformView {
    private val configuration =
        creationParams[CARD_COMPONENT_CONFIGURATION_KEY] as CardComponentConfigurationDTO?
            ?: throw Exception("Card configuration not found")
    internal val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
    internal val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""
    internal val isStoredPaymentMethod = creationParams[IS_STORED_PAYMENT_METHOD_KEY] as Boolean? ?: false
    private val dynamicComponentView = DynamicComponentView(activity, componentFlutterApi, componentId)
    internal val cardConfiguration =
        configuration.cardConfiguration.mapToCardConfiguration(
            context,
            configuration.shopperLocale,
            configuration.environment.mapToEnvironment(),
            configuration.clientKey,
            configuration.analyticsOptionsDTO.mapToAnalyticsConfiguration(),
            configuration.amount?.mapToAmount(),
        )
    internal var cardComponent: CardComponent? = null

    override fun getView(): View = dynamicComponentView

    override fun dispose() {
        dynamicComponentView.onDispose()
        cardComponent = null
        onDispose(componentId)
    }

    fun addComponent(cardComponent: CardComponent) {
        dynamicComponentView.addComponent(cardComponent, activity)
    }

    fun setCurrentCardComponent() = setCurrentCardComponent(this)

    companion object {
        const val CARD_COMPONENT_CONFIGURATION_KEY = "cardComponentConfiguration"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
        const val CARD_PAYMENT_METHOD_KEY = "scheme"
        const val COMPONENT_ID_KEY = "componentId"
    }
}
