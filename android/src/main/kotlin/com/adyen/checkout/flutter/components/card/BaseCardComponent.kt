package com.adyen.checkout.flutter.components.card

import CardComponentConfigurationDTO
import ComponentFlutterInterface
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.children
import androidx.core.view.doOnNextLayout
import androidx.core.view.updateLayoutParams
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.flutter.R
import com.adyen.checkout.flutter.components.ComponentHeightMessenger
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.components.view.ComponentWrapperView
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.launch

abstract class BaseCardComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    context: Context,
    id: Int,
    creationParams: Map<*, *>
) : PlatformView {
    private val configuration =
        creationParams[CARD_COMPONENT_CONFIGURATION_KEY] as CardComponentConfigurationDTO?
            ?: throw Exception("Card configuration not found")
    private val environment = configuration.environment.fromDTO()
    private val componentWrapperView = ComponentWrapperView(activity, componentFlutterApi)
    val cardConfiguration =
        configuration.cardConfiguration.fromDTO(
            context,
            configuration.shopperLocale,
            environment,
            configuration.clientKey,
            configuration.analyticsOptionsDTO.mapToAnalyticsConfiguration(),
            configuration.amount.fromDTO(),
        )

    internal var cardComponent: CardComponent? = null

    override fun getView(): View = componentWrapperView

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)
        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    override fun dispose() {
        ComponentHeightMessenger.instance().removeObservers(activity)
        cardComponent = null
    }

    fun addComponent(
        cardComponent: CardComponent,
        componentId: String
    ) {
        componentWrapperView.addComponent(cardComponent, componentId)
    }

    fun assignCurrentComponent() {
        activity.lifecycleScope.launch {
            ComponentPlatformApi.currentComponentStateFlow.emit(cardComponent)
        }
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val linearLayoutParams =
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        // Adyen component view
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams =
            ConstraintLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )

        // Component container
        val componentContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
        componentContainer.layoutParams = linearLayoutParams

        // Button container
        val buttonContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
        buttonContainer.layoutParams = linearLayoutParams

        // Pay button
        val button = buttonContainer.children.firstOrNull()
        val buttonParams =
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
        button?.layoutParams = buttonParams

        // Card
        val card = componentContainer.children.firstOrNull() as ViewGroup?
        card?.updateLayoutParams {
            height = LinearLayout.LayoutParams.WRAP_CONTENT
        }
    }

    companion object {
        const val CARD_COMPONENT_CONFIGURATION_KEY = "cardComponentConfiguration"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
        const val CARD_PAYMENT_METHOD_KEY = "scheme"
        const val COMPONENT_ID_KEY = "componentId"
    }
}
