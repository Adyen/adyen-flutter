package com.adyen.checkout.flutter.components.googlepay.session

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponentWrapper
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import java.util.UUID

class GooglePaySessionComponentWrapper(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val checkoutConfiguration: CheckoutConfiguration,
    private val componentId: String,
    private val checkoutSession: CheckoutSession,
) : BaseGooglePayComponentWrapper(activity, componentFlutterInterface, componentId) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        googlePayComponent =
            GooglePayComponent.PROVIDER.get(
                activity = activity,
                checkoutSession = checkoutSession,
                paymentMethod = paymentMethod,
                checkoutConfiguration = checkoutConfiguration,
                componentCallback =
                    GooglePaySessionCallback(
                        componentFlutterInterface,
                        componentId,
                        ::onLoading,
                        ::handleAction,
                        ::hideLoadingBottomSheet
                    ),
                key = UUID.randomUUID().toString()
            )
    }

    private fun handleAction(action: Action) {
        googlePayComponent?.let {
            it.handleAction(action, activity)
            ComponentLoadingBottomSheet.show(activity, it)
        }
    }
}
