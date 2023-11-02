package com.adyen.adyen_checkout.components.card.advancedFlow

import CardComponentConfigurationDTO
import ComponentFlutterApi
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.children
import androidx.core.view.doOnNextLayout
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.ComponentMessenger
import com.adyen.adyen_checkout.components.ComponentWrapperView
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject
import java.util.UUID

internal class CardAdvancedFlowComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : PlatformView {
    private val configuration = creationParams?.get("cardComponentConfiguration") as CardComponentConfigurationDTO
    private val paymentMethods = creationParams?.get("paymentMethods") as String
    private val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))
    private val paymentMethod = paymentMethodsApiResponse.paymentMethods?.first { it.type == "scheme" }
        ?: throw Exception("Card payment method not provided")
    private val environment = configuration.environment.toNativeModel()
    private val cardConfiguration = configuration.cardConfiguration.toNativeModel(
        context,
        environment,
        configuration.clientKey
    )
    private var cardComponent = CardComponent.PROVIDER.get(
        activity = activity,
        paymentMethod = paymentMethod,
        configuration = cardConfiguration,
        callback = CardAdvancedFlowCallback(componentFlutterApi),
        key = UUID.randomUUID().toString()
    )
    private val componentWrapperView = ComponentWrapperView(activity, componentFlutterApi)

    init {
        componentWrapperView.addComponent(cardComponent)
        addActionListener()
    }

    override fun getView(): View = componentWrapperView

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)

        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    override fun dispose() {
        ComponentMessenger.instance().removeObservers(activity)
        cardComponent.delegate.onCleared()
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val linearLayoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        //Adyen component view
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams = linearLayoutParams

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

    private fun addActionListener() {
        ComponentMessenger.instance().observe(activity) { message ->
            val action = message.contentIfNotHandled?.let { Action.SERIALIZER.deserialize(it) }
            action?.let {
                cardComponent.handleAction(action = it, activity = activity)
            }
        }
    }
}
