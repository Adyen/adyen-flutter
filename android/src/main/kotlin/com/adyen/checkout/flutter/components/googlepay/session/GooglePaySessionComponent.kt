package com.adyen.checkout.flutter.components.googlepay.session

import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponent
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_SESSION_REQUEST_CODE
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import java.util.UUID

class GooglePaySessionComponent(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponent(
    InstantPaymentType.GOOGLEPAYSESSION,
    activity,
    componentId,
) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod): GooglePayComponent {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession = CheckoutSession(sessionSetupResponse = sessionSetupResponse, order = order)
        GooglePayComponent.PROVIDER.get(
            activity,
            checkoutSession,
            paymentMethod,
            googlePayConfiguration,
            GooglePaySessionCallback(componentFlutterApi, componentId, ::onAction, ::hideLoadingBottomSheet),
            UUID.randomUUID().toString()
        ).apply {
            googlePayComponent = this
            return this
        }
    }

    override fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen(activity, GOOGLE_PAY_SESSION_REQUEST_CODE)
    }

    private fun onAction(action: Action) {
        googlePayComponent?.apply {
            handleAction(action, activity)
            val loadingBottomSheet = ComponentLoadingBottomSheet(this)
            loadingBottomSheet.isCancelable = false
            loadingBottomSheet.show(activity.supportFragmentManager, ComponentLoadingBottomSheet.TAG)
        }
    }
}
