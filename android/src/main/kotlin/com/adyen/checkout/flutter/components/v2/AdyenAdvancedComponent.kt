package com.adyen.checkout.flutter.components.v2

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.old.CardComponent
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.common.PaymentResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutResult
import com.adyen.checkout.core.components.paymentmethod.PaymentComponentState
import com.adyen.checkout.flutter.components.card.advanced.CardAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.PlatformException
import org.json.JSONObject
import java.util.UUID

internal class AdyenAdvancedComponent(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val onDispose: (String) -> Unit,
    private val setCurrentComponent: (BaseComponent) -> Unit
) : BaseComponent(context, id, creationParams, activity, componentFlutterApi, onDispose, setCurrentComponent) {
    init {
        val paymentMethod = com.adyen.checkout.core.components.data.model.PaymentMethod.SERIALIZER.deserialize(
            JSONObject(paymentMethodString)
        )
        val checkoutCallbacks = CheckoutCallbacks(
            onSubmit = { it ->
                println("ON SUBMIT INVOKED: ${it}")
                return@CheckoutCallbacks CheckoutResult.Finished("")
            },
            onAdditionalDetails = { it ->
                println("ON ADDITIONAL DETAILS INVOKED: ${it}")
                return@CheckoutCallbacks CheckoutResult.Finished("")
            },
            onFinished = { it: PaymentResult ->
                println("ON FINISHED INVOKED: ${it.sessionResult}")
            },
            onError = {
                println("ON ERROR INVOKED")
            },
        )

//        dynamicComponentView.addV6Component(
//            paymentMethod = paymentMethod,
//            callbacks = checkoutCallbacks
//        )
    }

    private fun createCardComponent(): CardComponent {
        val paymentMethodJson = JSONObject(paymentMethodString)
        when (isStoredPaymentMethod) {
            true -> {
                val storedPaymentMethod = StoredPaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    storedPaymentMethod = storedPaymentMethod,
                    configuration = checkoutConfiguration.getConfiguration(PaymentMethodTypes.SCHEME)!!,
                    callback =
                        CardAdvancedCallback(
                            componentFlutterApi,
                            componentId,
                            ::setCurrentCardComponent,
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            false -> {
                val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
                return CardComponent.PROVIDER.get(
                    activity = activity,
                    paymentMethod = paymentMethod,
                    configuration = checkoutConfiguration.getConfiguration(PaymentMethodTypes.SCHEME)!!,
                    callback =
                        CardAdvancedCallback(
                            componentFlutterApi,
                            componentId,
                            ::setCurrentCardComponent,
                        ),
                    key = UUID.randomUUID().toString()
                )
            }
        }
    }
}
