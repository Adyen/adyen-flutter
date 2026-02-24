package com.adyen.checkout.flutter.dropIn

import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.core.old.Environment
import com.adyen.checkout.core.old.Environment.Companion.TEST
import com.adyen.checkout.dropin.old.DropInCallback
import com.adyen.checkout.dropin.old.DropInResult
import com.adyen.checkout.dropin.old.SessionDropInCallback
import com.adyen.checkout.dropin.old.SessionDropInResult
import com.adyen.checkout.dropin.old.internal.ui.model.DropInResultContractParams
import com.adyen.checkout.dropin.old.internal.ui.model.SessionDropInResultContractParams
import com.adyen.checkout.flutter.dropIn.advanced.DropInAdditionalDetailsPlatformMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInAdditionalDetailsResultMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInBalanceCheckResultMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInOrderCancelResultMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInOrderRequestResultMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionPlatformMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentMethodDeletionResultMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInPaymentResultMessenger
import com.adyen.checkout.flutter.dropIn.advanced.DropInServiceResultMessenger
import com.adyen.checkout.flutter.dropIn.model.DropInServiceEvent
import com.adyen.checkout.flutter.generated.CheckoutEvent
import com.adyen.checkout.flutter.generated.CheckoutEventType
import com.adyen.checkout.flutter.generated.CheckoutFlutterInterface
import com.adyen.checkout.flutter.generated.DeletedStoredPaymentMethodResultDTO
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.DropInPlatformInterface
import com.adyen.checkout.flutter.generated.OrderCancelResultDTO
import com.adyen.checkout.flutter.generated.PaymentEventDTO
import com.adyen.checkout.flutter.generated.PaymentEventType
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.generated.PaymentResultModelDTO
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

internal class DropInPlatformApi(
    private val checkoutFlutter: CheckoutFlutterInterface,
    private val activity: FragmentActivity,
    private val checkoutHolder: CheckoutHolder,
) : DropInPlatformInterface {
    lateinit var dropInSessionLauncher: ActivityResultLauncher<SessionDropInResultContractParams>
    lateinit var dropInAdvancedFlowLauncher: ActivityResultLauncher<DropInResultContractParams>
    private var dropInPlatformMessengerJob: Job? = null

    companion object {
        val dropInMessageFlow = MutableSharedFlow<CheckoutEvent>()
        val dropInServiceFlow = MutableSharedFlow<DropInServiceEvent>()
    }

    override fun showDropInSession(dropInConfigurationDTO: DropInConfigurationDTO) {
        setStoredPaymentMethodDeletionObserver()
        val dropInConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
        val checkoutSession =
            createCheckoutSession(
                checkoutHolder,
                TEST, // TODO Change back to generic
                dropInConfigurationDTO.clientKey
            )

        dropInPlatformMessengerJob?.cancel()
        dropInPlatformMessengerJob =
            activity.lifecycleScope.launch { dropInMessageFlow.collect { event -> checkoutFlutter.send(event) {} } }

//        DropIn.startPayment(
//            activity.applicationContext,
//            dropInSessionLauncher,
//            checkoutSession,
//            dropInConfiguration,
//            SessionDropInService::class.java
//        )
    }

    override fun showDropInAdvanced(
        dropInConfigurationDTO: DropInConfigurationDTO,
        paymentMethodsResponse: String,
    ) {
        setAdvancedFlowDropInServiceObserver()
        setStoredPaymentMethodDeletionObserver()

        dropInPlatformMessengerJob?.cancel()
        dropInPlatformMessengerJob =
            activity.lifecycleScope.launch { dropInMessageFlow.collect { event -> checkoutFlutter.send(event) {} } }

        activity.lifecycleScope.launch(Dispatchers.IO) {
            val paymentMethodsApiResponse =
                PaymentMethodsApiResponse.SERIALIZER.deserialize(
                    JSONObject(paymentMethodsResponse),
                )
            val paymentMethodsWithoutGiftCards =
                removeGiftCardPaymentMethods(
                    paymentMethodsApiResponse,
                    dropInConfigurationDTO.isPartialPaymentSupported
                )
            val dropInConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
            withContext(Dispatchers.Main) {
//                DropIn.startPayment(
//                    context = activity.applicationContext,
//                    dropInLauncher = dropInAdvancedFlowLauncher,
//                    paymentMethods = paymentMethodsWithoutGiftCards,
//                    checkoutConfiguration = dropInConfiguration,
//                    dropInServiceClass = AdvancedDropInService::class.java,
//                )
            }
        }
    }

    override fun stopDropIn() {
        activity.lifecycleScope.launch {
            dropInServiceFlow.emit(DropInServiceEvent.STOP)
        }
    }

    override fun onPaymentsResult(paymentsResult: PaymentEventDTO) {
        if (paymentsResult.paymentEventType == PaymentEventType.ACTION) {
            setAdvanceFlowDropInAdditionalDetailsMessengerObserver()
        }

        DropInPaymentResultMessenger.sendResult(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        DropInAdditionalDetailsResultMessenger.sendResult(paymentsDetailsResult)
    }

    override fun onDeleteStoredPaymentMethodResult(
        deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO
    ) {
        DropInPaymentMethodDeletionResultMessenger.sendResult(deleteStoredPaymentMethodResultDTO)
    }

    override fun onBalanceCheckResult(balanceCheckResponse: String) {
        DropInBalanceCheckResultMessenger.sendResult(balanceCheckResponse)
    }

    override fun onOrderRequestResult(orderRequestResponse: String) {
        DropInOrderRequestResultMessenger.sendResult(orderRequestResponse)
    }

    override fun onOrderCancelResult(orderCancelResult: OrderCancelResultDTO) {
        DropInOrderCancelResultMessenger.sendResult(orderCancelResult)
    }

    override fun cleanUpDropIn() {
        dropInPlatformMessengerJob?.cancel()

        DropInServiceResultMessenger.instance().removeObservers(activity)
        DropInAdditionalDetailsPlatformMessenger.instance().removeObservers(activity)
        DropInPaymentMethodDeletionPlatformMessenger.instance().removeObservers(activity)
        DropInBalanceCheckResultMessenger.instance().removeObservers(activity)
        DropInOrderRequestResultMessenger.instance().removeObservers(activity)
        DropInOrderCancelResultMessenger.instance().removeObservers(activity)
    }

    private fun setAdvancedFlowDropInServiceObserver() {
        DropInServiceResultMessenger.instance().removeObservers(activity)
        DropInServiceResultMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val checkoutEvent =
                CheckoutEvent(
                    CheckoutEventType.SUBMIT,
                    data = message.contentIfNotHandled.toString()
                )
            checkoutFlutter.send(checkoutEvent) {}
        }
    }

    private fun setStoredPaymentMethodDeletionObserver() {
        DropInPaymentMethodDeletionPlatformMessenger.instance().removeObservers(activity)
        DropInPaymentMethodDeletionPlatformMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val dropInStoredPaymentMethodDeletionModel = message.contentIfNotHandled
            val checkoutEvent =
                CheckoutEvent(
                    CheckoutEventType.DELETE_STORED_PAYMENT_METHOD,
                    data = dropInStoredPaymentMethodDeletionModel?.storedPaymentMethodId,
                )

            checkoutFlutter.send(checkoutEvent) {}
        }
    }

    private fun setAdvanceFlowDropInAdditionalDetailsMessengerObserver() {
        DropInAdditionalDetailsPlatformMessenger.instance().removeObservers(activity)
        DropInAdditionalDetailsPlatformMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val checkoutEvent =
                CheckoutEvent(
                    CheckoutEventType.ADDITIONAL_DETAILS,
                    data = message.contentIfNotHandled.toString(),
                )

            checkoutFlutter.send(checkoutEvent) {}
        }
    }

    private fun createCheckoutSession(
        checkoutHolder: CheckoutHolder,
        environment: Environment,
        clientKey: String,
    ): CheckoutSession {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(checkoutHolder.sessionSetupResponse)
//        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        return CheckoutSession(
            sessionSetupResponse = sessionSetupResponse,
            order = null,
            environment = environment,
            clientKey = clientKey
        )
    }

    private fun removeGiftCardPaymentMethods(
        paymentMethodsResponse: PaymentMethodsApiResponse,
        isPartialPaymentSupported: Boolean
    ): PaymentMethodsApiResponse {
        if (isPartialPaymentSupported) {
            return paymentMethodsResponse
        }

        val giftCardTypeIdentifier = "giftcard"
        val storedPaymentMethods =
            paymentMethodsResponse.storedPaymentMethods?.filterNot { it.type == giftCardTypeIdentifier }
        val paymentMethods = paymentMethodsResponse.paymentMethods?.filterNot { it.type == giftCardTypeIdentifier }

        return PaymentMethodsApiResponse(
            storedPaymentMethods = storedPaymentMethods,
            paymentMethods = paymentMethods
        )
    }

    val sessionDropInCallback =
        SessionDropInCallback { sessionDropInResult ->
            if (sessionDropInResult == null) {
                return@SessionDropInCallback
            }

            val mappedResult =
                when (sessionDropInResult) {
                    is SessionDropInResult.CancelledByUser ->
                        PaymentResultDTO(
                            PaymentResultEnum.CANCELLED_BY_USER
                        )

                    is SessionDropInResult.Error ->
                        PaymentResultDTO(
                            PaymentResultEnum.ERROR,
                            reason = sessionDropInResult.reason
                        )

                    is SessionDropInResult.Finished ->
                        PaymentResultDTO(
                            PaymentResultEnum.FINISHED,
                            result =
                                with(sessionDropInResult.result) {
                                    PaymentResultModelDTO(
                                        sessionId,
                                        sessionResult,
                                        resultCode,
                                        order?.mapToOrderResponseModel()
                                    )
                                }
                        )
                }

            val checkoutEvent =
                CheckoutEvent(
                    CheckoutEventType.RESULT,
                    mappedResult,
                )

            checkoutFlutter.send(checkoutEvent) {}
        }

    val dropInAdvancedFlowCallback =
        DropInCallback { dropInAdvancedFlowResult ->
            if (dropInAdvancedFlowResult == null) {
                return@DropInCallback
            }

            val mappedResult =
                when (dropInAdvancedFlowResult) {
                    is DropInResult.CancelledByUser ->
                        PaymentResultDTO(
                            PaymentResultEnum.CANCELLED_BY_USER
                        )

                    is DropInResult.Error ->
                        PaymentResultDTO(
                            PaymentResultEnum.ERROR,
                            reason = dropInAdvancedFlowResult.reason
                        )

                    is DropInResult.Finished ->
                        PaymentResultDTO(
                            PaymentResultEnum.FINISHED,
                            result =
                                PaymentResultModelDTO(
                                    resultCode = dropInAdvancedFlowResult.result
                                )
                        )
                }

            val checkoutEvent =
                CheckoutEvent(
                    CheckoutEventType.RESULT,
                    mappedResult
                )
            checkoutFlutter.send(checkoutEvent) {}
        }
}
