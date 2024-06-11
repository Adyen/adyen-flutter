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
import kotlinx.coroutines.delay
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
    private val layoutChangeHeightFlow = MutableStateFlow<Int?>(null)
    private var isComponentRendered = false
    private var oldComponentViewHeight = 0.0
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
        cardComponent = null
    }

    fun addComponent(cardComponent: CardComponent) {
        adyenComponentView.attach(cardComponent, activity)
        val vto: ViewTreeObserver = adyenComponentView.getViewTreeObserver()
        vto.addOnGlobalLayoutListener(object : OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                adjustCardComponentLayout()
                isComponentRendered = true
//                setupLayoutListener()
                triggerResize()

                val obs: ViewTreeObserver = adyenComponentView.getViewTreeObserver()
                obs.removeOnGlobalLayoutListener(this)
            }
        })
    }

//    fun setupLayoutListener() {
//        activity.lifecycleScope.launch {
//            layoutChangeHeightFlow.debounce(300).collect {
//                it?.let {
//                    println("Trigger :$it")
//                    triggerResize()
//                }
//            }
//        }
//
//        activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)?.addOnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
//            activity.lifecycleScope.launch {
//                layoutChangeHeightFlow.emit(v.height)
//            }
//        }
//    }

    fun assignCurrentComponent() {
        activity.lifecycleScope.launch {
            ComponentPlatformApi.currentComponentStateFlow.emit(cardComponent)
        }
    }

    fun triggerResize() {
        if (!isComponentRendered) {
            return
        }

        val cardComponentHeight = activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)?.height ?: 0
        val buttonHeight = activity.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)?.height ?: 0
        val schemeIconOffset = standardMargin * 2
        var containerHeight = (cardComponentHeight + buttonHeight + schemeIconOffset).toDouble()
        if (configuration.cardConfiguration.addressMode == AddressMode.FULL) {
            containerHeight += standardMargin * 2 //error message cover
        }
        val containerHeightScreenDensity = (containerHeight / screenDensity)
        val roundedHeight = round(containerHeightScreenDensity * 100) / 100
        if (oldComponentViewHeight == roundedHeight) {
            return
        }

        oldComponentViewHeight = roundedHeight
        println("Height: $roundedHeight")
        componentFlutterApi.onComponentCommunication(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESIZE,
                componentId = componentId,
                data = roundedHeight
            )
        ) {}
    }

    private fun adjustCardComponentLayout() {
        val linearLayoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )

        // Component container
        val componentContainer = activity.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
        componentContainer.layoutParams = linearLayoutParams

        // Button container
        val buttonContainer = activity.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
        buttonContainer.layoutParams = linearLayoutParams
    }

    companion object {
        const val CARD_COMPONENT_CONFIGURATION_KEY = "cardComponentConfiguration"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
        const val CARD_PAYMENT_METHOD_KEY = "scheme"
        const val COMPONENT_ID_KEY = "componentId"
    }
}
