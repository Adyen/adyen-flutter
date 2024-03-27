package com.adyen.checkout.flutter.components.googlepay.session

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponentWrapper
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import java.util.UUID

class GooglePaySessionComponentWrapper(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponentWrapper(activity, componentFlutterInterface) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession = CheckoutSession(sessionSetupResponse = sessionSetupResponse, order = order)
        googlePayComponent =
            GooglePayComponent.PROVIDER.get(
                activity = activity,
                checkoutSession = checkoutSession,
                paymentMethod = paymentMethod,
                configuration = googlePayConfiguration,
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
}
