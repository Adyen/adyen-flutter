package com.adyen.adyen_checkout.components.card.advancedFlow

import ComponentFlutterApi
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.doOnNextLayout
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.ComponentActionMessenger
import com.adyen.adyen_checkout.components.card.BaseCardComponent
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.ui.core.AdyenComponentView
import org.json.JSONObject
import java.util.UUID

internal class CardAdvancedFlowComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val paymentMethods = creationParams?.get("paymentMethods") as String
    private val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))
    private val paymentMethod = paymentMethodsApiResponse.paymentMethods?.first { it.type == "scheme" }
        ?: throw Exception("Card payment method not provided")

    init {
        cardComponent = CardComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            configuration = cardConfiguration,
            callback = CardAdvancedFlowCallback(componentFlutterApi),
            key = UUID.randomUUID().toString()
        )

        addComponent(cardComponent)
        addActionListener()
    }

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)

        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
    }

    private fun addActionListener() {
        ComponentActionMessenger.instance().observe(activity) { message ->
            val action = message.contentIfNotHandled?.let { Action.SERIALIZER.deserialize(it) }
            action?.let {
                cardComponent.handleAction(action = it, activity = activity)
            }
        }
    }
}
