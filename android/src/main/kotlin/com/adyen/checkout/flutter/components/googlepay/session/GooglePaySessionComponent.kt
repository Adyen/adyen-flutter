package com.adyen.checkout.flutter.components.googlepay.session

import ComponentCommunicationModel
import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
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
) : BaseGooglePayComponent(activity) {
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
                componentCallback = GooglePaySessionCallback(
                    componentFlutterApi,
                    componentId,
                    ::onLoading,
                    ::onAction,
                    ::hideLoadingBottomSheet
                ),
                key = UUID.randomUUID().toString()
            )
    }

    override fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen(activity, GOOGLE_PAY_SESSION_REQUEST_CODE)
    }

    private fun onLoading() {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId,
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    private fun onAction(action: Action) {
        googlePayComponent?.let {
            it.handleAction(action, activity)
            ComponentLoadingBottomSheet.show(activity.supportFragmentManager, it)
        }
    }

    override fun dispose() = clear()
}
