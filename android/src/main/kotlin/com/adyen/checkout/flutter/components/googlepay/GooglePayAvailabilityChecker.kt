package com.adyen.checkout.flutter.components.googlepay

import InstantPaymentSetupResultDTO
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.googlepay.GooglePayButtonParameters
import com.adyen.checkout.googlepay.GooglePayComponent

class GooglePayAvailabilityChecker(
    private val activity: FragmentActivity,
) : ComponentAvailableCallback {
    private var googlePayButtonParameters: GooglePayButtonParameters? = null
    private var googlePaySetupCallback: ((Result<InstantPaymentSetupResultDTO>) -> Unit)? = null

    override fun onAvailabilityResult(
        isAvailable: Boolean,
        paymentMethod: PaymentMethod
    ) {
        if (isAvailable) {
            googlePaySetupCallback?.invoke(
                Result.success(
                    InstantPaymentSetupResultDTO(
                        InstantPaymentType.GOOGLEPAY,
                        true,
                        googlePayButtonParameters?.allowedPaymentMethods.orEmpty()
                    )
                )
            )
        } else {
            googlePaySetupCallback?.invoke(Result.failure(Exception("Google pay not available")))
        }
    }

    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        checkoutConfiguration: CheckoutConfiguration,
        googlePayButtonParameters: GooglePayButtonParameters?,
        googlePaySetupCallback: ((Result<InstantPaymentSetupResultDTO>) -> Unit)
    ) {
        this.googlePayButtonParameters = googlePayButtonParameters
        this.googlePaySetupCallback = googlePaySetupCallback
        GooglePayComponent.PROVIDER.isAvailable(
            activity.application,
            paymentMethod,
            checkoutConfiguration,
            this@GooglePayAvailabilityChecker,
        )
    }

    fun clear() {
        googlePayButtonParameters = null
        googlePaySetupCallback = null
    }
}
