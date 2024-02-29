package com.adyen.checkout.flutter.components.googlepay

import ComponentFlutterInterface
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.advanced.GooglePayAdvancedComponent
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionComponent
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration

class GooglePayComponentManager(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) {
    private val googlePayComponents: MutableList<BaseGooglePayComponent> = mutableListOf()

    fun isGooglePayAvailable(
        paymentMethod: PaymentMethod,
        componentId: String,
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        googlePaySetupCallback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
            googlePaySetupCallback(
                Result.success(
                    InstantPaymentSetupResultDTO(
                        instantPaymentComponentConfigurationDTO.instantPaymentType,
                        false
                    )
                )
            )
        }

        val googlePlayConfiguration: GooglePayConfiguration =
            instantPaymentComponentConfigurationDTO.mapToGooglePayConfiguration(activity)
        val googlePayComponent: BaseGooglePayComponent =
            setupGooglePayComponent(googlePlayConfiguration, componentId, paymentMethod)
        val googlePayAvailabilityChecker =
            GooglePayAvailabilityChecker(activity, googlePayComponents, googlePayComponent, googlePaySetupCallback)
        googlePayAvailabilityChecker.checkGooglePayAvailability(paymentMethod, googlePlayConfiguration)
    }

    fun startGooglePayScreen(componentId: String) {
        googlePayComponents.firstOrNull { it.componentId == componentId }?.startGooglePayScreen()
    }

    private fun setupGooglePayComponent(
        googlePayConfiguration: GooglePayConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): BaseGooglePayComponent {
        // TODO - Replace check via keys with session object when it is provided from the Flutter layer.
        if (componentId.contains(Constants.GOOGLE_PAY_ADVANCED_COMPONENT_KEY)) {
            return createGooglePayAdvancedComponent(googlePayConfiguration, componentId, paymentMethod)
        } else if (componentId.contains(Constants.GOOGLE_PAY_SESSION_COMPONENT_KEY)) {
            return createGooglePaySessionComponent(googlePayConfiguration, componentId, paymentMethod)
        }

        throw IllegalStateException("Google Pay not available")
    }

    private fun createGooglePaySessionComponent(
        googlePayConfiguration: GooglePayConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePaySessionComponent =
        GooglePaySessionComponent(
            activity,
            sessionHolder,
            componentFlutterInterface,
            googlePayConfiguration,
            componentId
        ).apply {
            setupGooglePayComponent(paymentMethod)
        }

    private fun createGooglePayAdvancedComponent(
        googlePayConfiguration: GooglePayConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePayAdvancedComponent {
        return GooglePayAdvancedComponent(
            activity,
            componentFlutterInterface,
            googlePayConfiguration,
            componentId
        ).apply {
            setupGooglePayComponent(paymentMethod)
        }
    }

    fun handleGooglePayActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean {
        return when (requestCode) {
            Constants.GOOGLE_PAY_SESSION_REQUEST_CODE -> {
                googlePayComponents.firstOrNull { it is GooglePaySessionComponent }
                    ?.handleActivityResult(resultCode, data)
                true
            }

            Constants.GOOGLE_PAY_ADVANCED_REQUEST_CODE -> {
                googlePayComponents.firstOrNull { it is GooglePayAdvancedComponent }
                    ?.handleActivityResult(resultCode, data)
                true
            }

            else -> false
        }
    }

    fun onDispose(componentId: String) {
        googlePayComponents.firstOrNull { it.componentId == componentId }.apply {
            this?.dispose()
            googlePayComponents.remove(this)
        }
    }
}
