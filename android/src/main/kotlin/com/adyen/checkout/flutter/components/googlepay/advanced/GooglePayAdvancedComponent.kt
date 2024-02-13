package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponent
import com.adyen.checkout.googlepay.GooglePayComponent

class GooglePayAdvancedComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
) : BaseGooglePayComponent(
        InstantPaymentType.GOOGLEPAYADVANCED,
        activity,
    ) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod): GooglePayComponent {
        return GooglePayComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            configuration = googlePayConfiguration,
            callback = GooglePayAdvancedCallback(componentFlutterApi, componentId, ::hideLoadingBottomSheet),
        )
    }
}
