package com.adyen.checkout.flutter.components.googlepay

import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.InstantPaymentSetupResultDTO
import com.adyen.checkout.flutter.generated.InstantPaymentType
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import com.adyen.checkout.ui.core.old.AdyenComponentView
import java.util.UUID

class GooglePayComponentManager(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) : ComponentAvailableCallback {
    private var componentId: String? = null
    private var checkoutConfiguration: CheckoutConfiguration? = null
    private var googlePayComponent: GooglePayComponent? = null
    private var adyenComponentView: AdyenComponentView? = null

    override fun onAvailabilityResult(
        isAvailable: Boolean,
        paymentMethod: PaymentMethod
    ) {
        if (!isAvailable) {
            sendAvailabilityResult(false, "Google Pay is not available")
            return
        }

        val googlePayComponent = createGooglePayComponent(paymentMethod)
        if (googlePayComponent == null) {
            sendAvailabilityResult(false, "Google Pay setup failed")
            return
        }

        this.googlePayComponent = googlePayComponent
        this.adyenComponentView =
            AdyenComponentView(activity).apply {
                attach(googlePayComponent, activity)
            }

        val allowedPaymentMethods = googlePayComponent.getGooglePayButtonParameters().allowedPaymentMethods
        sendAvailabilityResult(true, allowedPaymentMethods)
    }

    fun initialize(
        paymentMethod: PaymentMethod,
        componentId: String,
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
    ) {
        if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
            sendAvailabilityResult(false)
            return
        }

        val checkoutConfiguration = instantPaymentComponentConfigurationDTO.toCheckoutConfiguration()
        this.componentId = componentId
        this.checkoutConfiguration = checkoutConfiguration
        GooglePayComponent.PROVIDER.isAvailable(
            activity.application,
            paymentMethod,
            checkoutConfiguration,
            this,
        )
    }

    fun start() {
        googlePayComponent?.let {
            assignCurrentComponent(it)
            googlePayComponent?.startGooglePayScreen(activity, Constants.GOOGLE_PAY_COMPONENT_REQUEST_CODE)
        }
    }

    fun handleGooglePayActivityResult(
        resultCode: Int,
        data: Intent?
    ) = googlePayComponent?.handleActivityResult(resultCode, data)

    fun onDispose(componentId: String) {
        if (componentId == Constants.GOOGLE_PAY_ADVANCED_COMPONENT_KEY ||
            componentId == Constants.GOOGLE_PAY_SESSION_COMPONENT_KEY
        ) {
            this.componentId = null
            checkoutConfiguration = null
            googlePayComponent = null
            adyenComponentView = null
        }
    }

    private fun createGooglePayComponent(paymentMethod: PaymentMethod): GooglePayComponent? {
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
    ): GooglePayComponent {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession =
            CheckoutSession(
                sessionSetupResponse,
                order,
                checkoutConfiguration.environment,
                checkoutConfiguration.clientKey
            )
        return GooglePayComponent.PROVIDER.get(
            activity = activity,
            checkoutSession = checkoutSession,
            paymentMethod = paymentMethod,
            checkoutConfiguration = checkoutConfiguration,
            componentCallback =
                GooglePaySessionCallback(
                    componentFlutterInterface,
                    componentId,
                    ::handleAction,
                    ::hideLoadingBottomSheet
                ),
            key = UUID.randomUUID().toString()
        )
    }

    private fun createGooglePayAdvancedComponent(
        checkoutConfiguration: CheckoutConfiguration,
        componentId: String,
        paymentMethod: PaymentMethod,
    ): GooglePayComponent =
        GooglePayComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            checkoutConfiguration = checkoutConfiguration,
            callback =
                GooglePayAdvancedCallback(
                    componentFlutterInterface,
                    componentId,
                    ::hideLoadingBottomSheet
                ),
            key = UUID.randomUUID().toString()
        )

    fun handleAction(action: Action) {
        googlePayComponent?.let {
            it.handleAction(action, activity)
            ComponentLoadingBottomSheet.show(activity.supportFragmentManager, it)
        }
    }

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    private fun sendAvailabilityResult(
        isAvailable: Boolean,
        resultData: String? = null
    ) {
        val componentId = componentId ?: return
        componentFlutterInterface.onComponentCommunication(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.AVAILABILITY,
                componentId = componentId,
                data =
                    InstantPaymentSetupResultDTO(
                        InstantPaymentType.GOOGLE_PAY,
                        isAvailable,
                        resultData
                    )
            )
        ) {}
    }
}
