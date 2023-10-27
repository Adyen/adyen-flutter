package com.adyen.adyen_checkout.components.card

import CardComponentConfigurationDTO
import ComponentFlutterApi
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.doOnNextLayout
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.ComponentWrapperView
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject
import java.util.UUID

internal class CardComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : PlatformView {
    private val configuration = creationParams?.get("cardComponentConfiguration") as CardComponentConfigurationDTO
    private val paymentMethods = creationParams?.get("paymentMethods") as String
    private val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))
    private val schemes = paymentMethodsApiResponse.paymentMethods?.first { it.type == "scheme" }
        ?: throw Exception("Card payment method not provided")
    private val environment = configuration.environment.toNativeModel()
    private val cardConfiguration = configuration.cardConfiguration.toNativeModel(
        context,
        environment,
        configuration.clientKey
    )
    private var cardComponent = CardComponent.PROVIDER.get(
        activity = activity,
        paymentMethod = schemes,
        configuration = cardConfiguration,
        callback = CardCallback(componentFlutterApi),
        key = UUID.randomUUID().toString()
    )
    private val componentWrapperView = ComponentWrapperView(activity, componentFlutterApi)

    init {
        componentWrapperView.addComponent(cardComponent)
    }

    override fun getView(): View = componentWrapperView

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)

        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    override fun dispose() {
        Log.d("AdyenCheckout", "DISPOSE VIEW")
        cardComponent.delegate.onCleared()
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val param = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams = param

        //Container
        var container = flutterView.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
        container.layoutParams = param

        //Button container
        var buttonContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
        buttonContainer.layoutParams = param

        //Button
        var button = flutterView.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer).getChildAt(0)
        val buttonParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        button.layoutParams = buttonParams

        // CARD
        var card = flutterView.findViewById<FrameLayout>(R.id.frameLayout_componentContainer).getChildAt(0) as ViewGroup
        var layoutparams = card.layoutParams
        layoutparams.height = LinearLayout.LayoutParams.WRAP_CONTENT
        card.layoutParams = layoutparams
    }
}
