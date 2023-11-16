package com.adyen.adyen_checkout.components.card

import CardComponentConfigurationDTO
import ComponentFlutterApi
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.children
import androidx.core.view.doOnNextLayout
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.ComponentActionMessenger
import com.adyen.adyen_checkout.components.ComponentHeightMessenger
import com.adyen.adyen_checkout.components.ComponentWrapperView
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView

abstract class BaseCardComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : PlatformView {
    private val configuration = creationParams?.get("cardComponentConfiguration") as CardComponentConfigurationDTO
    private val environment = configuration.environment.toNativeModel()
    private val componentWrapperView = ComponentWrapperView(activity, componentFlutterApi)
    val cardConfiguration = configuration.cardConfiguration.toNativeModel(
        context,
        environment,
        configuration.clientKey
    )

    lateinit var cardComponent: CardComponent

    override fun getView(): View = componentWrapperView

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)

        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    override fun dispose() {
        ComponentActionMessenger.instance().removeObservers(activity)
        ComponentHeightMessenger.instance().removeObservers(activity)
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val linearLayoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        //Adyen component view
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams = ConstraintLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )

        //Component container
        val componentContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
        componentContainer.layoutParams = linearLayoutParams

        //Button container
        val buttonContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
        buttonContainer.layoutParams = linearLayoutParams

        //Pay button
        val button = buttonContainer.children.firstOrNull()
        val buttonParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        button?.layoutParams = buttonParams

        //Card
        val card = componentContainer.children.firstOrNull() as ViewGroup?
        val cardLayoutParams = card?.layoutParams
        cardLayoutParams?.height = LinearLayout.LayoutParams.WRAP_CONTENT
        card?.layoutParams = cardLayoutParams
    }

    fun addComponent(cardComponent: CardComponent) {
        componentWrapperView.addComponent(cardComponent)
    }
}
