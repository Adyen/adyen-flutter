package com.adyen.checkout.flutter.components.googlepay

import InstantPaymentSetupResultDTO
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.googlepay.GooglePayComponent

class GooglePayAvailabilityChecker(
    private val activity: FragmentActivity,
    private val googlePayComponent: BaseGooglePayComponentWrapper?,
    private val googlePaySetupCallback: (Result<InstantPaymentSetupResultDTO>) -> Unit,
) : ComponentAvailableCallback {
    override fun onAvailabilityResult(
        isAvailable: Boolean,
        paymentMethod: PaymentMethod
    ) {
        if (isAvailable) {
            googlePaySetupCallback(
                Result.success(
                    InstantPaymentSetupResultDTO(
                        InstantPaymentType.GOOGLEPAY,
                        true,
                        googlePayComponent?.googlePayComponent?.getGooglePayButtonParameters()
                            ?.allowedPaymentMethods.orEmpty()
                    )
                )
            )
        } else {
            googlePaySetupCallback(Result.failure(Exception("Google pay not available")))
        }
    }

    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        checkoutConfiguration: CheckoutConfiguration,
    ) = GooglePayComponent.PROVIDER.isAvailable(
        activity.application,
        paymentMethod,
        checkoutConfiguration,
        this@GooglePayAvailabilityChecker,
    )
}
