package com.adyen.adyen_checkout.components.card.advancedFlow

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.core.view.doOnNextLayout
import androidx.fragment.app.FragmentActivity
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.ComponentActionMessenger
import com.adyen.adyen_checkout.components.ComponentErrorMessenger
import com.adyen.adyen_checkout.components.ComponentResultMessenger
import com.adyen.adyen_checkout.components.card.BaseCardComponent
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.ui.core.AdyenComponentView
import org.json.JSONObject
import java.util.UUID

internal class CardAdvancedFlowComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val paymentMethods = creationParams?.get(PAYMENT_METHODS_KEY) as String
    private val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))
    private val paymentMethod = paymentMethodsApiResponse.paymentMethods?.first { it.type == SCHEME_KEY }
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
        addResultListener()
        addErrorListener()
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
        ComponentActionMessenger.instance().removeObservers(activity)
        ComponentActionMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val action = message.contentIfNotHandled?.let { Action.SERIALIZER.deserialize(it) }
            action?.let {
                cardComponent.handleAction(action = it, activity = activity)
            }
        }
    }

    private fun addResultListener() {
        ComponentResultMessenger.instance().removeObservers(activity)
        ComponentResultMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val model = ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
                paymentResult = message.contentIfNotHandled,
            )
            componentFlutterApi.onComponentCommunication(model) {}
        }
    }

    private fun addErrorListener() {
        ComponentErrorMessenger.instance().removeObservers(activity)
        ComponentErrorMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }


            val model = ComponentCommunicationModel(
                ComponentCommunicationType.ERROR,
                data = message.contentIfNotHandled?.errorMessage,
            )
            componentFlutterApi.onComponentCommunication(model) {}
        }
    }

    companion object {
        const val PAYMENT_METHODS_KEY = "paymentMethods"
        const val SCHEME_KEY = "scheme"
    }
}
