package com.adyen.checkout.flutter.components.googlepay

import ComponentFlutterInterface
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.advanced.GooglePayAdvancedComponentWrapper
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionComponentWrapper
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import java.lang.Exception

class GooglePayComponentManager(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) {
    private var googlePayComponent: BaseGooglePayComponentWrapper? = null
    private val googlePayAvailabilityChecker = GooglePayAvailabilityChecker(activity)

    fun isGooglePayAvailable(
        paymentMethod: PaymentMethod,
        componentId: String,
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        googlePaySetupCallback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        try {
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

            when (componentId) {
                Constants.GOOGLE_PAY_ADVANCED_COMPONENT_KEY -> {
                    setupGooglePayAdvancedComponent(
                        instantPaymentComponentConfigurationDTO,
                        componentId,
                        paymentMethod,
                        googlePaySetupCallback
                    )
                }

                Constants.GOOGLE_PAY_SESSION_COMPONENT_KEY -> {
                    setupGooglePaySessionComponent(
                        instantPaymentComponentConfigurationDTO,
                        componentId,
                        paymentMethod,
                        googlePaySetupCallback
                    )
                }

                else -> throw IllegalStateException("Google Pay not available")
            }
        } catch (exception: Exception) {
            googlePaySetupCallback(Result.failure(exception))
        }
    }

    private fun setupGooglePayAdvancedComponent(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        componentId: String,
        paymentMethod: PaymentMethod,
        googlePaySetupCallback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        val checkoutConfiguration: CheckoutConfiguration =
            instantPaymentComponentConfigurationDTO.mapToCheckoutConfiguration()
        val googlePayAdvancedComponent =
            createGooglePayAdvancedComponent(checkoutConfiguration, componentId, paymentMethod)
        val googlePayButtonParameters = googlePayAdvancedComponent.googlePayComponent?.getGooglePayButtonParameters()
        googlePayComponent = googlePayAdvancedComponent
        googlePayAvailabilityChecker.checkGooglePayAvailability(
            paymentMethod,
            checkoutConfiguration,
            googlePayButtonParameters,
            googlePaySetupCallback
        )
    }

    private fun setupGooglePaySessionComponent(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        componentId: String,
        paymentMethod: PaymentMethod,
        googlePaySetupCallback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        val sessionSetupResponse =
            SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutConfiguration: CheckoutConfiguration =
            instantPaymentComponentConfigurationDTO.mapToCheckoutConfiguration()
        val checkoutSession =
            CheckoutSession(
                sessionSetupResponse,
                order,
                checkoutConfiguration.environment,
                checkoutConfiguration.clientKey
            )

        val googlePaySessionComponent =
            createGooglePaySessionComponent(checkoutSession, checkoutConfiguration, componentId, paymentMethod)
        val googlePayButtonParameters = googlePaySessionComponent.googlePayComponent?.getGooglePayButtonParameters()
        googlePayComponent = googlePaySessionComponent
        googlePayAvailabilityChecker.checkGooglePayAvailability(
            paymentMethod,
            checkoutConfiguration,
            googlePayButtonParameters,
            googlePaySetupCallback
        )
    }

    fun startGooglePayComponent() {
        googlePayComponent?.let {
            assignCurrentComponent(it.googlePayComponent)
            it.startGooglePayScreen()
        }
    }

    private fun createGooglePaySessionComponent(
        checkoutSession: CheckoutSession,
        checkoutConfiguration: CheckoutConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePaySessionComponentWrapper =
        GooglePaySessionComponentWrapper(
            activity,
            checkoutSession,
            componentFlutterInterface,
            checkoutConfiguration,
            componentId
        ).apply {
            setupGooglePayComponent(paymentMethod)
        }

    private fun createGooglePayAdvancedComponent(
        checkoutConfiguration: CheckoutConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePayAdvancedComponentWrapper {
        return GooglePayAdvancedComponentWrapper(
            activity,
            componentFlutterInterface,
            checkoutConfiguration,
            componentId
        ).apply {
            setupGooglePayComponent(paymentMethod)
        }
    }

    fun handleGooglePayActivityResult(
        resultCode: Int,
        data: Intent?
    ) {
        googlePayComponent?.handleActivityResult(resultCode, data)
    }

    fun onDispose(componentId: String) {
        if (componentId == Constants.GOOGLE_PAY_ADVANCED_COMPONENT_KEY ||
            componentId == Constants.GOOGLE_PAY_SESSION_COMPONENT_KEY
        ) {
            googlePayAvailabilityChecker.clear()
            googlePayComponent?.dispose(componentId)
        }
    }
}
