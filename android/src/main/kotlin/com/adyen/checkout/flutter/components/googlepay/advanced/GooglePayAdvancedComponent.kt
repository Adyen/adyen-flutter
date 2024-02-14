package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponent
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_ADVANCED_REQUEST_CODE
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration

class GooglePayAdvancedComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponent(
    InstantPaymentType.GOOGLEPAYADVANCED,
    activity,
    componentId,
) {
    init {
        addActionListener()
        addResultListener()
    }

    override fun setupGooglePayComponent(paymentMethod: PaymentMethod): GooglePayComponent {
        GooglePayComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            configuration = googlePayConfiguration,
            callback = GooglePayAdvancedCallback(componentFlutterApi, componentId, ::hideLoadingBottomSheet),
        ).apply {
            googlePayComponent = this
            return this
        }
    }

    override fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen(activity, GOOGLE_PAY_ADVANCED_REQUEST_CODE)
    }

    private fun addActionListener() {

    }

    private fun addResultListener() {
    }
}
