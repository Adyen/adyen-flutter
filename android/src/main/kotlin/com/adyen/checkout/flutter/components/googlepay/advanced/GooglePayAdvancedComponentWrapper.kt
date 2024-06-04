package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponentWrapper
import com.adyen.checkout.googlepay.GooglePayComponent
import java.util.UUID

class GooglePayAdvancedComponentWrapper(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val checkoutConfiguration: CheckoutConfiguration,
    private val componentId: String,
) : BaseGooglePayComponentWrapper(activity, componentFlutterInterface, componentId) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        googlePayComponent =
            GooglePayComponent.PROVIDER.get(
                activity = activity,
                paymentMethod = paymentMethod,
                checkoutConfiguration = checkoutConfiguration,
                callback =
                    GooglePayAdvancedCallback(
                        componentFlutterInterface,
                        componentId,
                        ::onLoading,
                        ::hideLoadingBottomSheet
                    ),
                key = UUID.randomUUID().toString()
            )
    }
}
