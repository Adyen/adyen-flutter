package com.adyen.checkout.flutter.components.googlepay

import ComponentFlutterInterface
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
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
) : ComponentAvailableCallback {
    private var componentId: String? = null
    private var checkoutConfiguration: CheckoutConfiguration? = null
    private var setupCallback: ((Result<InstantPaymentSetupResultDTO>) -> Unit)? = null
    private var componentWrapper: BaseGooglePayComponentWrapper? = null

    override fun onAvailabilityResult(
        isAvailable: Boolean,
        paymentMethod: PaymentMethod
    ) {
        if (isAvailable) {
            val componentWrapper = createWrapperWithComponent(paymentMethod)
            if (componentWrapper == null) {
                setupCallback?.invoke(Result.failure(Exception("Google Pay setup failed")))
                return
            }

            this.componentWrapper = componentWrapper
            val allowedPaymentMethods =
                componentWrapper.googlePayComponent?.getGooglePayButtonParameters()?.allowedPaymentMethods.orEmpty()
            setupCallback?.invoke(
                Result.success(
                    InstantPaymentSetupResultDTO(
                        InstantPaymentType.GOOGLEPAY,
                        true,
                        allowedPaymentMethods
                    )
                )
            )
        } else {
            setupCallback?.invoke(Result.failure(Exception("Google Pay is not available")))
        }
    }

    fun initialize(
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
        val checkoutConfiguration = instantPaymentComponentConfigurationDTO.mapToCheckoutConfiguration()
        this.componentId = componentId
        this.checkoutConfiguration = checkoutConfiguration
        this.setupCallback = googlePaySetupCallback
        GooglePayComponent.PROVIDER.isAvailable(
            activity.application,
            paymentMethod,
            checkoutConfiguration,
            this,
        )
    }

    fun start() {
        componentWrapper?.let {
            assignCurrentComponent(it.googlePayComponent)
            it.startGooglePayScreen()
        }
    }

    fun handleGooglePayActivityResult(
        resultCode: Int,
        data: Intent?
    ) = componentWrapper?.handleActivityResult(resultCode, data)

    fun onDispose(componentId: String) {
        if (componentId == Constants.GOOGLE_PAY_ADVANCED_COMPONENT_KEY ||
            componentId == Constants.GOOGLE_PAY_SESSION_COMPONENT_KEY
        ) {
            this.componentId = null
            checkoutConfiguration = null
            setupCallback = null
            componentWrapper?.dispose(componentId)
        }
    }

    private fun createWrapperWithComponent(paymentMethod: PaymentMethod): BaseGooglePayComponentWrapper? {
        val checkoutConfiguration = checkoutConfiguration ?: return null
        val componentId = componentId ?: return null
        return when (componentId) {
            Constants.GOOGLE_PAY_SESSION_COMPONENT_KEY ->
                createGooglePaySessionComponent(
                    checkoutConfiguration,
                    componentId,
                    paymentMethod
                )

            Constants.GOOGLE_PAY_ADVANCED_COMPONENT_KEY ->
                createGooglePayAdvancedComponent(
                    checkoutConfiguration,
                    componentId,
                    paymentMethod
                )

            else -> null
        }
    }

    private fun createGooglePaySessionComponent(
        checkoutConfiguration: CheckoutConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePaySessionComponentWrapper {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession =
            CheckoutSession(
                sessionSetupResponse,
                order,
                checkoutConfiguration.environment,
                checkoutConfiguration.clientKey
            )
        return GooglePaySessionComponentWrapper(
            activity,
            componentFlutterInterface,
            checkoutConfiguration,
            componentId,
            checkoutSession
        ).apply {
            setupGooglePayComponent(paymentMethod)
        }
    }

    private fun createGooglePayAdvancedComponent(
        checkoutConfiguration: CheckoutConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePayAdvancedComponentWrapper =
        GooglePayAdvancedComponentWrapper(
            activity,
            componentFlutterInterface,
            checkoutConfiguration,
            componentId
        ).apply {
            setupGooglePayComponent(paymentMethod)
        }
}
