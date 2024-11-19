package com.adyen.checkout.flutter.dropIn.advanced

import DeletedStoredPaymentMethodResultDTO
import ErrorDTO
import OrderCancelResponseDTO
import PaymentEventDTO
import PaymentEventType
import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ServiceLifecycleDispatcher
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.BalanceResult
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.StoredPaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.dropin.BalanceDropInServiceResult
import com.adyen.checkout.dropin.DropInService
import com.adyen.checkout.dropin.DropInServiceResult
import com.adyen.checkout.dropin.ErrorDialog
import com.adyen.checkout.dropin.OrderDropInServiceResult
import com.adyen.checkout.dropin.RecurringDropInServiceResult
import com.adyen.checkout.flutter.dropIn.model.DropInStoredPaymentMethodDeletionModel
import com.adyen.checkout.flutter.dropIn.model.DropInType
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponentState
import org.json.JSONObject

class AdvancedDropInService : DropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)

    override fun onSubmit(state: PaymentComponentState<*>) = onPaymentComponentState(state)

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        try {
            setAdvancedFlowDropInAdditionalDetailsObserver()
            val actionComponentJson = ActionComponentData.SERIALIZER.serialize(actionComponentData)
            DropInAdditionalDetailsPlatformMessenger.sendResult(actionComponentJson)
        } catch (exception: Exception) {
            sendResult(
                DropInServiceResult.Error(
                    errorDialog = null,
                    reason = exception.message,
                    dismissDropIn = true
                )
            )
        }
    }

    override fun onBalanceCheck(paymentComponentState: PaymentComponentState<*>) {
        try {
            setBalanceCheckObserver()
            val data = PaymentComponentData.SERIALIZER.serialize(paymentComponentState.data)
            DropInBalanceCheckPlatformMessenger.sendResult(data)
        } catch (exception: Exception) {
            sendResult(
                DropInServiceResult.Error(
                    errorDialog = null,
                    reason = exception.message,
                    dismissDropIn = true
                )
            )
        }
    }

    override fun onOrderRequest() {
        setOrderRequestObserver()
        DropInOrderRequestPlatformMessenger.sendResult("onOrderRequest")
    }

    override fun onOrderCancel(
        order: Order,
        shouldUpdatePaymentMethods: Boolean
    ) {
        setOrderCancelObserver()
        val cancelOrderData = JSONObject()
        cancelOrderData.put(Constants.ORDER_KEY, Order.SERIALIZER.serialize(order))
        cancelOrderData.put(Constants.SHOULD_UPDATE_PAYMENT_METHODS_KEY, shouldUpdatePaymentMethods)
        DropInOrderCancelPlatformMessenger.sendResult(cancelOrderData)
    }

    override fun onRemoveStoredPaymentMethod(storedPaymentMethod: StoredPaymentMethod) {
        storedPaymentMethod.id?.let { storedPaymentMethodId ->
            setStoredPaymentMethodDeletionObserver()
            val dropInStoredPaymentMethodDeletionModel =
                DropInStoredPaymentMethodDeletionModel(
                    storedPaymentMethodId,
                    DropInType.ADVANCED_FLOW
                )
            DropInPaymentMethodDeletionPlatformMessenger.sendResult(dropInStoredPaymentMethodDeletionModel)
        } ?: run {
            sendRecurringResult(RecurringDropInServiceResult.Error(errorDialog = ErrorDialog()))
        }
    }

    private fun onPaymentComponentState(state: PaymentComponentState<*>) {
        try {
            setAdvancedFlowDropInServiceObserver()
            val data = PaymentComponentData.SERIALIZER.serialize(state.data)
            val extra = (state as? GooglePayComponentState)?.paymentData?.toJson()
            val submitData =
                JSONObject().apply {
                    put(Constants.ADVANCED_PAYMENT_DATA_KEY, data)
                    extra?.let {
                        put(Constants.ADVANCED_EXTRA_DATA_KEY, JSONObject(it))
                    }
                }
            DropInServiceResultMessenger.sendResult(submitData)
        } catch (exception: Exception) {
            sendResult(
                DropInServiceResult.Error(
                    errorDialog = null,
                    reason = exception.message,
                    dismissDropIn = true
                )
            )
        }
    }

    private fun setAdvancedFlowDropInServiceObserver() {
        DropInPaymentResultMessenger.instance().removeObservers(this)
        DropInPaymentResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val dropInServiceResult = mapToDropInServiceResult(message.contentIfNotHandled)
            sendResult(dropInServiceResult)
        }
    }

    private fun setAdvancedFlowDropInAdditionalDetailsObserver() {
        DropInAdditionalDetailsResultMessenger.instance().removeObservers(this)
        DropInAdditionalDetailsResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val dropInServiceResult = mapToDropInServiceResult(message.contentIfNotHandled)
            sendResult(dropInServiceResult)
        }
    }

    private fun setStoredPaymentMethodDeletionObserver() {
        DropInPaymentMethodDeletionResultMessenger.instance().removeObservers(this)
        DropInPaymentMethodDeletionResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val deletionResult = mapToDeletionDropInResult(message.contentIfNotHandled)
            sendRecurringResult(deletionResult)
        }
    }

    private fun setBalanceCheckObserver() {
        DropInBalanceCheckResultMessenger.instance().removeObservers(this)
        DropInBalanceCheckResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val balanceResult = mapToBalanceDropInServiceResult(message.contentIfNotHandled as String)
            sendBalanceResult(balanceResult)
        }
    }

    private fun setOrderRequestObserver() {
        DropInOrderRequestResultMessenger.instance().removeObservers(this)
        DropInOrderRequestResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val orderResult = mapToOrderDropInServiceResult(message.contentIfNotHandled as String)
            sendOrderResult(orderResult)
        }
    }

    private fun setOrderCancelObserver() {
        DropInOrderCancelResultMessenger.instance().removeObservers(this)
        DropInOrderCancelResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val orderResult = mapToOrderCancelDropInServiceResult(message.contentIfNotHandled) ?: return@observe
            sendResult(orderResult)
        }
    }

    private fun mapToDeletionDropInResult(
        deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO?
    ): RecurringDropInServiceResult {
        return if (deleteStoredPaymentMethodResultDTO?.isSuccessfullyRemoved == true) {
            RecurringDropInServiceResult.PaymentMethodRemoved(deleteStoredPaymentMethodResultDTO.storedPaymentMethodId)
        } else {
            // TODO - the error message should be provided by the native SDK
            RecurringDropInServiceResult.Error(
                errorDialog =
                    ErrorDialog(
                        message = "Removal of the stored payment method failed. Please try again later."
                    )
            )
        }
    }

    private fun mapToDropInServiceResult(paymentEventDTO: PaymentEventDTO?): DropInServiceResult {
        return when (paymentEventDTO?.paymentEventType) {
            PaymentEventType.FINISHED ->
                DropInServiceResult.Finished(
                    result = "${paymentEventDTO.result}"
                )

            PaymentEventType.ERROR ->
                DropInServiceResult.Error(
                    errorDialog = buildErrorDialog(paymentEventDTO.error),
                    reason = paymentEventDTO.error?.reason,
                    dismissDropIn = paymentEventDTO.error?.dismissDropIn ?: false
                )

            PaymentEventType.ACTION -> {
                if (paymentEventDTO.data == null) {
                    DropInServiceResult.Error(
                        errorDialog = null,
                        reason = "Action response not provided",
                        dismissDropIn = true
                    )
                } else {
                    val actionJson = JSONObject(paymentEventDTO.data)
                    DropInServiceResult.Action(action = Action.SERIALIZER.deserialize(actionJson))
                }
            }

            PaymentEventType.UPDATE -> {
                if (paymentEventDTO.data == null) {
                    DropInServiceResult.Error(
                        errorDialog = null,
                        reason = "Updated payment methods and order not provided",
                        dismissDropIn = true
                    )
                } else {
                    val updatedPaymentMethodsJSON =
                        JSONObject(paymentEventDTO.data[Constants.UPDATED_PAYMENT_METHODS_KEY] as HashMap<*, *>)
                    val orderResponseJSON =
                        JSONObject(paymentEventDTO.data[Constants.ORDER_RESPONSE_KEY] as HashMap<*, *>)
                    val paymentMethods = PaymentMethodsApiResponse.SERIALIZER.deserialize(updatedPaymentMethodsJSON)
                    val orderResponse = OrderResponse.SERIALIZER.deserialize(orderResponseJSON)
                    DropInServiceResult.Update(paymentMethods, orderResponse)
                }
            }

            null ->
                DropInServiceResult.Error(
                    errorDialog = null,
                    reason = "IOException",
                    dismissDropIn = true
                )
        }
    }

    private fun buildErrorDialog(dropInError: ErrorDTO?): ErrorDialog? {
        return if (dropInError?.dismissDropIn == true) {
            null
        } else {
            ErrorDialog(message = dropInError?.errorMessage)
        }
    }

    private fun mapToBalanceDropInServiceResult(response: String): BalanceDropInServiceResult {
        try {
            val jsonResponse = JSONObject(response)
            return when (val resultCode = jsonResponse.optString(Constants.RESULT_CODE_KEY)) {
                "Success" -> BalanceDropInServiceResult.Balance(BalanceResult.SERIALIZER.deserialize(jsonResponse))
                "NotEnoughBalance" ->
                    BalanceDropInServiceResult.Balance(
                        BalanceResult.SERIALIZER.deserialize(
                            jsonResponse
                        )
                    )

                else ->
                    BalanceDropInServiceResult.Error(
                        errorDialog =
                            ErrorDialog(
                                title = resultCode,
                                message = jsonResponse.optString(Constants.MESSAGE_KEY) ?: "Unknown"
                            ),
                        dismissDropIn = false
                    )
            }
        } catch (exception: Exception) {
            return BalanceDropInServiceResult.Error(
                errorDialog = null,
                reason = "Failure parsing balance check response."
            )
        }
    }

    private fun mapToOrderDropInServiceResult(response: String): OrderDropInServiceResult {
        try {
            val jsonResponse = JSONObject(response)
            return when (val resultCode = jsonResponse.optString(Constants.RESULT_CODE_KEY)) {
                "Success" -> OrderDropInServiceResult.OrderCreated(OrderResponse.SERIALIZER.deserialize(jsonResponse))
                else ->
                    OrderDropInServiceResult.Error(
                        errorDialog =
                            ErrorDialog(
                                title = resultCode,
                                message = jsonResponse.optString(Constants.MESSAGE_KEY) ?: "Unknown"
                            ),
                        dismissDropIn = false
                    )
            }
        } catch (exception: Exception) {
            return OrderDropInServiceResult.Error(
                errorDialog = null,
                reason = "Failure parsing order response."
            )
        }
    }

    private fun mapToOrderCancelDropInServiceResult(
        orderCancelResponseDTO: OrderCancelResponseDTO?
    ): DropInServiceResult? {
        try {
            val orderCancelResponseBody = orderCancelResponseDTO?.orderCancelResponseBody?.let { JSONObject(it) }
            return when (val resultCode = orderCancelResponseBody?.optString(Constants.RESULT_CODE_KEY)) {
                "Received" -> {
                    if (orderCancelResponseDTO.updatedPaymentMethods?.isNotEmpty() == true) {
                        val updatedPaymentMethods = orderCancelResponseDTO.updatedPaymentMethods
                        val paymentMethods =
                            PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(updatedPaymentMethods))
                        val orderResponse = OrderResponse.SERIALIZER.deserialize(orderCancelResponseBody)
                        sendResult(DropInServiceResult.Update(paymentMethods, orderResponse))
                    }
                    null
                }

                else ->
                    DropInServiceResult.Error(
                        errorDialog =
                            ErrorDialog(
                                title = resultCode,
                                message = orderCancelResponseBody?.optString(Constants.MESSAGE_KEY) ?: "Unknown"
                            ),
                        dismissDropIn = false,
                    )
            }
        } catch (exception: Exception) {
            return DropInServiceResult.Error(
                errorDialog = null,
                reason = "Failure parsing order cancellation response."
            )
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        dispatcher.onServicePreSuperOnBind()
        return super.onBind(intent)
    }

    override fun onCreate() {
        dispatcher.onServicePreSuperOnCreate()
        super.onCreate()
    }

    @Deprecated("Deprecated in Java")
    override fun onStart(
        intent: Intent?,
        startId: Int
    ) {
        dispatcher.onServicePreSuperOnStart()
        super.onStart(intent, startId)
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        dispatcher.onServicePreSuperOnStart()
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onDestroy() {
        dispatcher.onServicePreSuperOnDestroy()
        super.onDestroy()
    }

    override val lifecycle: Lifecycle
        get() = dispatcher.lifecycle
}
