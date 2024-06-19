package com.adyen.checkout.flutter.components.card.advanced

import ComponentFlutterInterface
import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.flutter.components.card.BaseCardComponent
import org.json.JSONObject
import java.util.UUID

internal class CardAdvancedComponent(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseCardComponent) -> Unit
) : BaseCardComponent(context, id, creationParams, activity, componentFlutterApi, onDispose, setCurrentCardComponent) {

    init {
        cardComponent =
            createCardComponent().apply {
                addComponent(this)
            }
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
                    callback = CardAdvancedCallback(componentFlutterApi, componentId, ::setCurrentCardComponent),
                    key = UUID.randomUUID().toString()
                )
            }

            false -> {
                val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    paymentMethod = paymentMethod,
                    configuration = cardConfiguration,
                    callback = CardAdvancedCallback(componentFlutterApi, componentId, ::setCurrentCardComponent),
                    key = UUID.randomUUID().toString()
                )
            }
        }
    }
}
