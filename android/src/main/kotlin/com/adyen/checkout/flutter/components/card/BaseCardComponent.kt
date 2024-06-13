package com.adyen.checkout.flutter.components.card

import CardComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.doOnNextLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.flutter.R
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAmount
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCardConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import com.adyen.checkout.ui.core.AdyenComponentView
import com.google.android.material.button.MaterialButton
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.launch
import kotlin.math.round

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
    val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""
    private val adyenComponentView = AdyenComponentView(activity)
    private val standardMargin = activity.resources.getDimension(R.dimen.standard_margin)
    private val screenDensity = activity.resources.displayMetrics.density
    private val onLayoutChangeListener =
        View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
            activity.lifecycleScope.launch {
                layoutChangeFlow.emit(v.height)
            }
        }
    val layoutChangeFlow = MutableStateFlow<Int?>(null)
    val cardConfiguration =
        configuration.cardConfiguration.mapToCardConfiguration(
            context,
            configuration.shopperLocale,
            configuration.environment.mapToEnvironment(),
            configuration.clientKey,
            configuration.analyticsOptionsDTO.mapToAnalyticsConfiguration(),
            configuration.amount?.mapToAmount(),
        )

    internal var cardComponent: CardComponent? = null

    override fun getView(): View = adyenComponentView

    override fun dispose() {
        activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
            ?.removeOnLayoutChangeListener(onLayoutChangeListener)
        cardComponent = null
    }

    fun addComponent(cardComponent: CardComponent) {
        adyenComponentView.attach(cardComponent, activity)
        onCardComponentLayout()
        setupComponentResizeListener()
    }

    fun assignCurrentComponent() {
        activity.lifecycleScope.launch {
            ComponentPlatformApi.currentComponentStateFlow.emit(cardComponent)
        }
    }

    private fun onCardComponentLayout() {
        val vto: ViewTreeObserver = adyenComponentView.getViewTreeObserver()
        vto.addOnGlobalLayoutListener(
            object : OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    adjustCardComponentLayout()
                    activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
                        ?.addOnLayoutChangeListener(onLayoutChangeListener)

                    val obs: ViewTreeObserver = adyenComponentView.getViewTreeObserver()
                    obs.removeOnGlobalLayoutListener(this)
                }
            }
        )
    }

    @OptIn(FlowPreview::class)
    private fun setupComponentResizeListener() {
        activity.lifecycleScope.launch {
            layoutChangeFlow.debounce(50).collect {
                if (it != null) {
                    adyenComponentView.doOnNextLayout {
                        resizeFlutterViewPort()
                    }
                }
            }
        }
    }

    fun resizeFlutterViewPort() {
        val cardComponentHeight = activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)?.height ?: 0
        val payButtonHeight = activity.findViewById<MaterialButton>(R.id.payButton)?.height ?: 0
        val componentViewHeight = (cardComponentHeight + payButtonHeight + standardMargin).toDouble()
        val componentViewHeightScreenDensity = (componentViewHeight / screenDensity)
        val roundedViewHeight = round(componentViewHeightScreenDensity * 100) / 100
        componentFlutterApi.onComponentCommunication(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESIZE,
                componentId = componentId,
                data = roundedViewHeight
            )
        ) {}
    }

    private fun adjustCardComponentLayout() {
        val linearLayoutParams =
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )

        // Component container
        val componentContainer = activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
        componentContainer?.layoutParams = linearLayoutParams

        // Button container
        val buttonContainer = activity.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
        buttonContainer?.layoutParams = linearLayoutParams
    }

    companion object {
        const val CARD_COMPONENT_CONFIGURATION_KEY = "cardComponentConfiguration"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
        const val CARD_PAYMENT_METHOD_KEY = "scheme"
        const val COMPONENT_ID_KEY = "componentId"
    }
}
