package com.adyen.checkout.flutter.components.instant

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.ActionHandlingMethod
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.core.old.exception.CheckoutException
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.generated.TwintConfigurationDTO
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.flutter.utils.Constants.Companion.UNKNOWN_PAYMENT_METHOD_TYPE_ERROR_MESSAGE
import com.adyen.checkout.ideal.IdealComponent
import com.adyen.checkout.instant.InstantPaymentComponent
import com.adyen.checkout.paybybank.PayByBankComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import com.adyen.checkout.twint.TwintComponent
import com.adyen.checkout.twint.twint
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
            val configuration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            when (paymentMethod.type) {
                null, PaymentMethodTypes.UNKNOWN ->
                    throw CheckoutException(UNKNOWN_PAYMENT_METHOD_TYPE_ERROR_MESSAGE)

//                PaymentMethodTypes.IDEAL -> showIdealPaymentComponent(componentId, configuration, paymentMethod)
//                PaymentMethodTypes.PAY_BY_BANK -> showPayByBankComponent(componentId, configuration, paymentMethod)
//                PaymentMethodTypes.TWINT -> showTwintComponent(componentId, configuration, paymentMethod)
//                else -> showInstantPaymentComponent(componentId, configuration, paymentMethod)
            }
        } catch (exception: Exception) {
            val model =
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESULT,
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

    private fun showIdealPaymentComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ) {
        val idealComponent =
            when (componentId) {
                Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                    val checkoutSession = createCheckoutSession(configuration)
                    IdealComponent.PROVIDER.get(
                        activity = activity,
                        checkoutSession = checkoutSession,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        componentCallback = createInstantComponentSessionCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                Constants.INSTANT_ADVANCED_COMPONENT_KEY -> {
                    IdealComponent.PROVIDER.get(
                        activity = activity,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        callback = createInstantComponentAdvancedCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                else -> throw IllegalStateException("Ideal component not available for payment flow.")
            }

        assignCurrentComponent(idealComponent)
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, idealComponent)
    }

    private fun showPayByBankComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ) {
        val payByBankComponent =
            when (componentId) {
                Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                    val checkoutSession = createCheckoutSession(configuration)
                    PayByBankComponent.PROVIDER.get(
                        activity = activity,
                        checkoutSession = checkoutSession,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        componentCallback = createInstantComponentSessionCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                Constants.INSTANT_ADVANCED_COMPONENT_KEY -> {
                    PayByBankComponent.PROVIDER.get(
                        activity = activity,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        callback = createInstantComponentAdvancedCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                else -> throw IllegalStateException("Pay By Bank component not available for payment flow.")
            }

        assignCurrentComponent(payByBankComponent)
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, payByBankComponent)
    }

    private fun showTwintComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ) {
        // We use the web redirect for now and prevent storing the payment method to align with iOS
        configuration.twint {
            setShowStorePaymentField(false)
            setActionHandlingMethod( ActionHandlingMethod.PREFER_WEB)
        }
        val twintComponent =
            when (componentId) {
                Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                    val checkoutSession = createCheckoutSession(configuration)
                    TwintComponent.PROVIDER.get(
                        activity = activity,
                        checkoutSession = checkoutSession,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        componentCallback = createInstantComponentSessionCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                Constants.INSTANT_ADVANCED_COMPONENT_KEY -> {
                    TwintComponent.PROVIDER.get(
                        activity = activity,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        callback = createInstantComponentAdvancedCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                else -> throw IllegalStateException("Twint component not available for payment flow.")
            }

        assignCurrentComponent(twintComponent)
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, twintComponent)
    }

    private fun showInstantPaymentComponent(
        componentId: String,
        configuration: CheckoutConfiguration,
        paymentMethod: PaymentMethod
    ) {
        val instantComponent =
            when (componentId) {
                Constants.INSTANT_SESSION_COMPONENT_KEY -> {
                    val checkoutSession = createCheckoutSession(configuration)
                    InstantPaymentComponent.PROVIDER.get(
                        activity = activity,
                        checkoutSession = checkoutSession,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        componentCallback = createInstantComponentSessionCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                Constants.INSTANT_ADVANCED_COMPONENT_KEY -> {
                    InstantPaymentComponent.PROVIDER.get(
                        activity = activity,
                        paymentMethod = paymentMethod,
                        checkoutConfiguration = configuration,
                        callback = createInstantComponentAdvancedCallback(componentId),
                        key = UUID.randomUUID().toString()
                    )
                }

                else -> throw IllegalStateException("Instant component not available for payment flow.")
            }

        assignCurrentComponent(instantComponent)
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, instantComponent)
    }

    private fun createCheckoutSession(configuration: CheckoutConfiguration): CheckoutSession {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
//        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        return CheckoutSession(
            sessionSetupResponse = sessionSetupResponse,
            order = null,
            environment = configuration.environment,
            clientKey = configuration.clientKey
        )
    }

    private fun <T : PaymentComponentState<*>> createInstantComponentSessionCallback(
        componentId: String
    ): InstantComponentSessionCallback<T> =
        InstantComponentSessionCallback(
            componentFlutterApi = componentFlutterInterface,
            componentId = componentId,
            onActionCallback = onAction,
            hideLoadingBottomSheet = ::hideLoadingBottomSheet
        )

    private fun <T : PaymentComponentState<*>> createInstantComponentAdvancedCallback(
        componentId: String
    ): InstantComponentAdvancedCallback<T> =
        InstantComponentAdvancedCallback(
            componentFlutterApi = componentFlutterInterface,
            componentId = componentId,
            hideLoadingBottomSheet = ::hideLoadingBottomSheet
        )

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
}
