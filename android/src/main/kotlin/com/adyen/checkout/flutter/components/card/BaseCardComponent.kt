package com.adyen.checkout.flutter.components.card

import CardComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.view.ViewTreeObserver.OnGlobalLayoutListener
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.doOnNextLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.flutter.R
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAmount
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCardConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.launch
import kotlin.math.round

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
    private val adyenComponentView = AdyenComponentView(activity)
    private val wrapperView = FrameLayout(context)
    private val standardMargin = activity.resources.getDimension(com.adyen.checkout.ui.core.R.dimen.standard_margin)
    private val screenDensity = activity.resources.displayMetrics.density
    private val layoutChangeFlow = MutableStateFlow<Int?>(null)
    private val onLayoutChangeListener =
        View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
            layoutChangeFlow.tryEmit(v.height)
        }
    internal val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
    internal val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""
    internal val isStoredPaymentMethod = creationParams[IS_STORED_PAYMENT_METHOD_KEY] as Boolean? ?: false
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

    override fun getView(): View = wrapperView

    override fun dispose() {
        activity.findViewById<FrameLayout>(com.adyen.checkout.ui.core.R.id.frameLayout_componentContainer)
            ?.removeOnLayoutChangeListener(onLayoutChangeListener)
        cardComponent = null
        onDispose(componentId)
    }

    fun addComponent(cardComponent: CardComponent) {
        wrapperView.addView(adyenComponentView)
        adyenComponentView.attach(cardComponent, activity)
        addSingleGlobalLayoutListener()
        setupComponentResizeListener()
    }

    fun setCurrentCardComponent() = setCurrentCardComponent(this)

    private fun addSingleGlobalLayoutListener() {
        adyenComponentView.getViewTreeObserver().addOnGlobalLayoutListener(
            object : OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    adjustCardComponentLayout()
                    activity.findViewById<FrameLayout>(com.adyen.checkout.ui.core.R.id.frameLayout_componentContainer)
                        ?.addOnLayoutChangeListener(onLayoutChangeListener)
                    adyenComponentView.getViewTreeObserver().removeOnGlobalLayoutListener(this)
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
        val componentViewHeight = adyenComponentView.height + standardMargin
        val componentViewHeightScreenDensity = componentViewHeight / screenDensity
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
        adyenComponentView.layoutParams =
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )

        val linearLayoutParams =
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )

        val componentContainer =
            activity.findViewById<FrameLayout>(
                com.adyen.checkout.ui.core.R.id.frameLayout_componentContainer
            )
        componentContainer?.layoutParams = linearLayoutParams
        val buttonContainer =
            activity.findViewById<FrameLayout>(
                com.adyen.checkout.ui.core.R.id.frameLayout_buttonContainer
            )
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
