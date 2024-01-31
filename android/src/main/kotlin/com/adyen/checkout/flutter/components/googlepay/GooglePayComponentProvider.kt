package com.adyen.checkout.flutter.components.googlepay

import InstantPaymentComponentConfigurationDTO
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.Locale

class GooglePayComponentProvider(val activity: FragmentActivity) : ComponentAvailableCallback {
    private val googlePayAvailableFlow = MutableStateFlow<Boolean?>(null)
    private var googlePayComponent: GooglePayComponent? = null
    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO,
    ) {
        activity.lifecycleScope.launch {
            if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
                googlePayAvailableFlow.emit(false)
            }

            GooglePayComponent.PROVIDER.isAvailable(
                activity.application,
                paymentMethod,
                buildGooglePayConfiguration(instantPaymentComponentConfigurationDTO),
                this@GooglePayComponentProvider,
            )
        }
    }

    fun setupGooglePayComponent() {
//        googlePayComponent = GooglePayComponent.PROVIDER.get(
//            activity,
//            paymentMethod = paymentMethod,
//            configuration = googlePayConfiguration,
//            callback = callback,
//        )
    }

    override fun onAvailabilityResult(isAvailable: Boolean, paymentMethod: PaymentMethod) {
        activity.lifecycleScope.launch {
            googlePayAvailableFlow.emit(isAvailable)
        }
    }

    private fun buildGooglePayConfiguration(instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO): GooglePayConfiguration {
        val googlePayConfigurationBuilder: GooglePayConfiguration.Builder =
            if (instantPaymentComponentConfigurationDTO.shopperLocale != null) {
                val locale = Locale.forLanguageTag(instantPaymentComponentConfigurationDTO.shopperLocale)
                GooglePayConfiguration.Builder(
                    locale,
                    instantPaymentComponentConfigurationDTO.environment.toNativeModel(),
                    instantPaymentComponentConfigurationDTO.clientKey
                )
            } else {
                GooglePayConfiguration.Builder(
                    activity,
                    instantPaymentComponentConfigurationDTO.environment.toNativeModel(),
                    instantPaymentComponentConfigurationDTO.clientKey
                )
            }

        return instantPaymentComponentConfigurationDTO.googlePayConfigurationDTO?.mapToGooglePayConfiguration(
            googlePayConfigurationBuilder
        ) ?: throw Exception("Unable to create Google pay configuration")
    }

}
