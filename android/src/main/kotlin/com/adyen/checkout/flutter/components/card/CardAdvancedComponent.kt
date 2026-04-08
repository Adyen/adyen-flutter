package com.adyen.checkout.flutter.components.card

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.old.CardComponent
import com.adyen.checkout.card.old.CardComponentState
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import org.json.JSONObject
import java.util.UUID

internal class CardAdvancedComponent(
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentEventHandler: ComponentPlatformEventHandler,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseCardComponent) -> Unit
) : BaseCardComponent(
    creationParams,
    activity,
    componentFlutterApi,
    componentEventHandler,
    onDispose,
    setCurrentCardComponent
) {
    init {
//        cardComponent =
//            createCardComponent().apply {
//                addComponent(this)
//            }
    }

//    private fun createCardComponent(): CardComponent {
//        val paymentMethodJson = JSONObject(paymentMethodString)
//        when (isStoredPaymentMethod) {
//            true -> {
//                val storedPaymentMethod = StoredPaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
//                return CardComponent.PROVIDER.get(
//                    activity = activity,
//                    storedPaymentMethod = storedPaymentMethod,
//                    checkoutConfiguration = checkoutConfiguration,
//                    callback =
//                        ComponentAdvancedCallback<CardComponentState>(
//                            componentFlutterApi,
//                            componentId,
//                            ::setCurrentCardComponent,
//                        ),
//                    key = UUID.randomUUID().toString()
//                )
//            }
//
//            false -> {
//                val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
//                return CardComponent.PROVIDER.get(
//                    activity = activity,
//                    paymentMethod = paymentMethod,
//                    checkoutConfiguration = checkoutConfiguration,
//                    callback =
//                        ComponentAdvancedCallback<CardComponentState>(
//                            componentFlutterApi,
//                            componentId,
//                            ::setCurrentCardComponent,
//                        ),
//                    key = UUID.randomUUID().toString()
//                )
//            }
//        }
//    }
}
