package com.adyen.adyen_checkout.components.card.advancedFlow

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
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
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.ui.core.AdyenComponentView
import org.json.JSONObject
import java.util.UUID

internal class CardAdvancedFlowComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    context: Context,
    id: Int,
    creationParams: Map<*, *>
) : BaseCardComponent(activity, componentFlutterApi, context, id, creationParams) {
    private val paymentMethodString = creationParams.getOrDefault(PAYMENT_METHOD_KEY, "") as String
    private val isStoredPaymentMethod = creationParams.getOrDefault(IS_STORED_PAYMENT_METHOD_KEY, false) as Boolean

    init {
        cardComponent = createCardComponent()
        addComponent(cardComponent)
        addActionListener()
        addResultListener()
        addErrorListener()
    }

    private fun createCardComponent(): CardComponent {
        val paymentMethodJson = JSONObject(paymentMethodString)
        when (isStoredPaymentMethod) {
            true -> {
                val storedPaymentMethod = StoredPaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    storedPaymentMethod = storedPaymentMethod,
                    configuration = cardConfiguration,
                    callback = CardAdvancedFlowCallback(componentFlutterApi),
                    key = UUID.randomUUID().toString()
                )
            }

            false -> {
                val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    paymentMethod = paymentMethod,
                    configuration = cardConfiguration,
                    callback = CardAdvancedFlowCallback(componentFlutterApi),
                    key = UUID.randomUUID().toString()
                )
            }
        }
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

}
