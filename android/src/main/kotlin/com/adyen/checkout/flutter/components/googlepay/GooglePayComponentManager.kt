package com.adyen.checkout.flutter.components.googlepay

import ComponentFlutterInterface
import ErrorDTO
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import PaymentEventDTO
import PaymentResultDTO
import PaymentResultModelDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.advanced.GooglePayAdvancedComponent
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionComponent
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import org.json.JSONObject

class GooglePayComponentManager(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) {
    private var googlePayComponent: BaseGooglePayComponent? = null

    companion object {
        var resultFlow = MutableStateFlow<String?>(null)
        var actionFlow = MutableStateFlow<JSONObject?>(null)
        var errorFlow = MutableStateFlow<ErrorDTO?>(null)
    }

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
        googlePayComponent = setupGooglePayComponent(googlePlayConfiguration, componentId, paymentMethod)
        val googlePayAvailabilityChecker =
            GooglePayAvailabilityChecker(activity, googlePayComponent, googlePaySetupCallback)
        googlePayAvailabilityChecker.checkGooglePayAvailability(paymentMethod, googlePlayConfiguration)
    }

    fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen()
    }

    fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        activity.lifecycleScope.launch {
            when (paymentEventDTO.paymentEventType) {
                PaymentEventType.FINISHED -> resultFlow.emit(paymentEventDTO.result)
                PaymentEventType.ACTION -> actionFlow.emit(JSONObject(paymentEventDTO.actionResponse!!))
                PaymentEventType.ERROR -> errorFlow.emit(paymentEventDTO.error)
            }
        }
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
        resultFlow = MutableStateFlow(null)
        actionFlow = MutableStateFlow(null)
        errorFlow = MutableStateFlow(null)

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
                googlePayComponent?.handleActivityResult(resultCode, data)
                true
            }

            Constants.GOOGLE_PAY_ADVANCED_REQUEST_CODE -> {
                googlePayComponent?.handleActivityResult(resultCode, data)
                true
            }

            else -> false
        }
    }

    fun onDispose() {
        googlePayComponent?.apply {
            dispose()
            googlePayComponent = null
        }
    }
}
