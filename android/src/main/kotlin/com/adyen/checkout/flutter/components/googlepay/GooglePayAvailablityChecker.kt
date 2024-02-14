package com.adyen.checkout.flutter.components.googlepay

import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.AnalyticsConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.Locale

class GooglePayAvailabilityChecker(
    private val activity: FragmentActivity,
    private val googlePayAvailableFlow: MutableStateFlow<Boolean?>
) : ComponentAvailableCallback {
    override fun onAvailabilityResult(isAvailable: Boolean, paymentMethod: PaymentMethod) {
        activity.lifecycleScope.launch {
            googlePayAvailableFlow.emit(isAvailable)
        }
    }

    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        googlePayConfiguration: GooglePayConfiguration,
    ) {
        GooglePayComponent.PROVIDER.isAvailable(
            activity.application,
            paymentMethod,
            googlePayConfiguration,
            this@GooglePayAvailabilityChecker,
        )
    }
}
