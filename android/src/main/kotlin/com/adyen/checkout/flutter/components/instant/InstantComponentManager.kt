package com.adyen.checkout.flutter.components.instant

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.core.exception.CheckoutException
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.flutter.utils.Constants.Companion.UNKNOWN_PAYMENT_METHOD_TYPE_ERROR_MESSAGE
import com.adyen.checkout.ideal.IdealComponent
import com.adyen.checkout.instant.InstantPaymentComponent
import com.adyen.checkout.paybybank.PayByBankComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import org.json.JSONObject
import java.util.UUID

class InstantComponentManager(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
    private val onAction: (Action) -> Unit,
) {
    fun start(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        encodedPaymentMethod: String,
        componentId: String
    ) {
        try {
            if (ComponentLoadingBottomSheet.isVisible(activity.supportFragmentManager)) {
                hideLoadingBottomSheet()
            }

            val paymentMethod = PaymentMethod.SERIALIZER.deserialize(JSONObject(encodedPaymentMethod))
            val configuration = instantPaymentConfigurationDTO.mapToCheckoutConfiguration()
            val component =
                when (paymentMethod.type) {
                    null, PaymentMethodTypes.UNKNOWN -> throw CheckoutException(
                        UNKNOWN_PAYMENT_METHOD_TYPE_ERROR_MESSAGE
                    )
                    PaymentMethodTypes.IDEAL -> createIdealPaymentComponent(componentId, configuration, paymentMethod)
                    PaymentMethodTypes.PAY_BY_BANK ->
                        createPayByBankComponent(
                            componentId,
                            configuration,
                            paymentMethod
                        )
                    else -> createInstantPaymentComponent(componentId, configuration, paymentMethod)
                }
            assignCurrentComponent(component)
            ComponentLoadingBottomSheet.show(activity.supportFragmentManager, component)
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
        }
    }

    private fun createInstantPaymentComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ): InstantPaymentComponent {
        when (componentId) {
            Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                val checkoutSession = createCheckoutSession(configuration)
                return InstantPaymentComponent.PROVIDER.get(
                    activity = activity,
                    checkoutSession = checkoutSession,
                    paymentMethod = paymentMethod,
                    checkoutConfiguration = configuration,
                    componentCallback =
                        InstantComponentSessionCallback(
                            componentFlutterApi = componentFlutterInterface,
                            componentId = componentId,
                            onActionCallback = onAction,
                            hideLoadingBottomSheet = ::hideLoadingBottomSheet
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            Constants.INSTANT_ADVANCED_COMPONENT_KEY -> return InstantPaymentComponent.PROVIDER.get(
                activity = activity,
                paymentMethod = paymentMethod,
                checkoutConfiguration = configuration,
                callback =
                    InstantComponentAdvancedCallback(
                        componentFlutterApi = componentFlutterInterface,
                        componentId = componentId,
                        hideLoadingBottomSheet = ::hideLoadingBottomSheet
                    ),
                key = UUID.randomUUID().toString()
            )

            else -> throw IllegalStateException("Instant component not available for payment flow.")
        }
    }

    private fun createIdealPaymentComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ): IdealComponent {
        when (componentId) {
            Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                val checkoutSession = createCheckoutSession(configuration)
                return IdealComponent.PROVIDER.get(
                    activity = activity,
                    checkoutSession = checkoutSession,
                    paymentMethod = paymentMethod,
                    checkoutConfiguration = configuration,
                    componentCallback =
                        InstantComponentSessionCallback(
                            componentFlutterApi = componentFlutterInterface,
                            componentId = componentId,
                            onActionCallback = onAction,
                            hideLoadingBottomSheet = ::hideLoadingBottomSheet
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            Constants.INSTANT_ADVANCED_COMPONENT_KEY -> {
                return IdealComponent.PROVIDER.get(
                    activity = activity,
                    paymentMethod = paymentMethod,
                    checkoutConfiguration = configuration,
                    callback =
                        InstantComponentAdvancedCallback(
                            componentFlutterApi = componentFlutterInterface,
                            componentId = componentId,
                            hideLoadingBottomSheet = ::hideLoadingBottomSheet
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            else -> throw IllegalStateException("Ideal component not available for payment flow.")
        }
    }

    private fun createPayByBankComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ): PayByBankComponent {
        when (componentId) {
            Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                val checkoutSession = createCheckoutSession(configuration)
                return PayByBankComponent.PROVIDER.get(
                    activity = activity,
                    checkoutSession = checkoutSession,
                    paymentMethod = paymentMethod,
                    checkoutConfiguration = configuration,
                    componentCallback =
                        InstantComponentSessionCallback(
                            componentFlutterApi = componentFlutterInterface,
                            componentId = componentId,
                            onActionCallback = onAction,
                            hideLoadingBottomSheet = ::hideLoadingBottomSheet
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            Constants.INSTANT_ADVANCED_COMPONENT_KEY -> {
                return PayByBankComponent.PROVIDER.get(
                    activity = activity,
                    paymentMethod = paymentMethod,
                    checkoutConfiguration = configuration,
                    callback =
                        InstantComponentAdvancedCallback(
                            componentFlutterApi = componentFlutterInterface,
                            componentId = componentId,
                            hideLoadingBottomSheet = ::hideLoadingBottomSheet
                        ),
                    key = UUID.randomUUID().toString()
                )
            }

            else -> throw IllegalStateException("Pay By Bank component not available for payment flow.")
        }
    }

    private fun createCheckoutSession(configuration: CheckoutConfiguration): CheckoutSession {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        return CheckoutSession(
            sessionSetupResponse = sessionSetupResponse,
            order = order,
            environment = configuration.environment,
            clientKey = configuration.clientKey
        )
    }

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
}
