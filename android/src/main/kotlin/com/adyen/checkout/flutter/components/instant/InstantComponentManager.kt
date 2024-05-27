package com.adyen.checkout.flutter.components.instant

import ComponentCommunicationModel
import ComponentFlutterInterface
import InstantPaymentConfigurationDTO
import PaymentResultDTO
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.instant.advanced.InstantComponentAdvancedCallback
import com.adyen.checkout.flutter.components.instant.session.InstantComponentSessionCallback
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.instant.InstantPaymentComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import org.json.JSONObject
import java.util.UUID

class InstantComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val sessionHolder: SessionHolder,
) {
    private var instantPaymentComponent: InstantPaymentComponent? = null
    private var componentId: String? = null

    fun startInstantComponent(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        encodedPaymentMethod: String,
        componentId: String
    ): InstantPaymentComponent? {
        try {
            val paymentMethod = PaymentMethod.SERIALIZER.deserialize(JSONObject(encodedPaymentMethod))
            val configuration = instantPaymentConfigurationDTO.mapToCheckoutConfiguration()
            val instantPaymentComponent =
                when (componentId) {
                    Constants.INSTANT_ADVANCED_COMPONENT_KEY ->
                        createInstantAdvancedComponent(
                            configuration,
                            paymentMethod,
                            componentId
                        )

                    Constants.INSTANT_SESSION_COMPONENT_KEY ->
                        createInstantSessionComponent(
                            configuration,
                            paymentMethod,
                            componentId
                        )

                    else -> throw IllegalStateException("Instant component not available for payment flow.")
                }

            this.instantPaymentComponent = instantPaymentComponent
            this.componentId = componentId
            showLoadingBottomSheet(instantPaymentComponent)
            return instantPaymentComponent
        } catch (exception: Exception) {
            val model =
                ComponentCommunicationModel(
                    ComponentCommunicationType.RESULT,
                    componentId = componentId,
                    paymentResult =
                        PaymentResultDTO(
                            type = PaymentResultEnum.ERROR,
                            reason = exception.message
                        ),
                )
            componentFlutterInterface.onComponentCommunication(model) {}
            return null
        }
    }

    fun onDispose(componentId: String) {
        if (componentId == this.componentId) {
            instantPaymentComponent = null
        }
    }

    private fun createInstantAdvancedComponent(
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod,
        componentId: String,
    ): InstantPaymentComponent {
        return InstantPaymentComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            checkoutConfiguration = configuration,
            callback =
                InstantComponentAdvancedCallback(
                    componentFlutterInterface,
                    componentId,
                    ::hideLoadingBottomSheet
                ),
            key = UUID.randomUUID().toString()
        )
    }

    private fun createInstantSessionComponent(
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod,
        componentId: String,
    ): InstantPaymentComponent {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession =
            CheckoutSession(
                sessionSetupResponse = sessionSetupResponse,
                order = order,
                environment = configuration.environment,
                clientKey = configuration.clientKey
            )
        return InstantPaymentComponent.PROVIDER.get(
            activity = activity,
            checkoutSession = checkoutSession,
            paymentMethod = paymentMethod,
            checkoutConfiguration = configuration,
            componentCallback =
                InstantComponentSessionCallback(
                    componentFlutterInterface,
                    componentId,
                    ::handleAction,
                    ::hideLoadingBottomSheet
                ),
            key = UUID.randomUUID().toString()
        )
    }

    private fun showLoadingBottomSheet(instantPaymentComponent: InstantPaymentComponent) =
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, instantPaymentComponent)

    private fun handleAction(action: Action) = instantPaymentComponent?.handleAction(action, activity)

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
}
