package com.adyen.checkout.flutter.components.blik

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.blik.old.BlikComponent
import com.adyen.checkout.blik.old.BlikComponentState
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.core.components.CheckoutConfiguration
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.components.base.ComponentAdvancedCallback
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import org.json.JSONObject
import java.util.UUID

internal class BlikAdvancedComponent(
    private val creationParams: Map<*, *>,
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentEventHandler: ComponentPlatformEventHandler,
    private val onDispose: (String) -> Unit,
    private val setCurrentBlikComponent: (BaseBlikComponent) -> Unit,
) : BaseBlikComponent(
    creationParams,
    activity,
    componentFlutterApi,
    componentEventHandler,
    onDispose,
    setCurrentBlikComponent,
) {
    init {
//        blikComponent =
//            createBlikComponent().apply {
//                addComponent(this)
//            }
    }

//    private fun createBlikComponent(): BlikComponent {
//        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(JSONObject(paymentMethodString))
//        return BlikComponent.PROVIDER.get(
//            activity = activity,
//            paymentMethod = paymentMethod,
//            checkoutConfiguration = checkoutConfiguration,
//            callback =
//                ComponentAdvancedCallback<BlikComponentState>(
//                    componentFlutterApi,
//                    componentId,
//                    ::setCurrentBlikComponent
//                ),
//            key = UUID.randomUUID().toString(),
//        )
//    }
}
