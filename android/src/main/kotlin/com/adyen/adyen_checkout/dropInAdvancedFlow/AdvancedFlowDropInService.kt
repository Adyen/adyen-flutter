package com.adyen.adyen_checkout.dropInAdvancedFlow


import DropInResult
import DropInResultType.*
import android.content.Intent
import android.os.IBinder
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ServiceLifecycleDispatcher
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.dropin.DropInService
import com.adyen.checkout.dropin.DropInServiceResult
import org.json.JSONObject

class AdvancedFlowDropInService : DropInService(), LifecycleOwner {
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

    override fun onBalanceCheck(paymentComponentState: PaymentComponentState<*>) =
        onPaymentComponentState(paymentComponentState)

    private fun onPaymentComponentState(paymentComponentState: PaymentComponentState<*>) {
        try {
            setAdvancedFlowDropInServiceObserver()
            val paymentComponentJson =
                PaymentComponentData.SERIALIZER.serialize(paymentComponentState.data)
            DropInServiceResultMessenger.sendResult(paymentComponentJson)
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

            val dropInServiceResult = mapToDropInResult(message.contentIfNotHandled)
            sendResult(dropInServiceResult)
        }
    }

    private fun setAdvancedFlowDropInAdditionalDetailsObserver() {
        DropInAdditionalDetailsResultMessenger.instance().removeObservers(this)
        DropInAdditionalDetailsResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val dropInServiceResult = mapToDropInResult(message.contentIfNotHandled)
            sendResult(dropInServiceResult)
        }
    }

    private fun mapToDropInResult(dropInResult: DropInResult?): DropInServiceResult {
        return when (dropInResult?.dropInResultType) {
            FINISHED -> DropInServiceResult.Finished(result = "${dropInResult.result}")

            ERROR -> DropInServiceResult.Error(
                errorDialog = null,
                reason = dropInResult.error?.reason,
                dismissDropIn = dropInResult.error?.dismissDropIn ?: false
            )

            ACTION -> {
                if (dropInResult.actionResponse == null) {
                    DropInServiceResult.Error(
                        errorDialog = null,
                        reason = "Action response not provided",
                        dismissDropIn = true
                    )
                } else {
                    val actionJson = JSONObject(dropInResult.actionResponse)
                    DropInServiceResult.Action(action = Action.SERIALIZER.deserialize(actionJson))
                }
            }

            null -> DropInServiceResult.Error(
                errorDialog = null,
                reason = "IOException",
                dismissDropIn = true
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
    override fun onStart(intent: Intent?, startId: Int) {
        dispatcher.onServicePreSuperOnStart()
        super.onStart(intent, startId)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
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