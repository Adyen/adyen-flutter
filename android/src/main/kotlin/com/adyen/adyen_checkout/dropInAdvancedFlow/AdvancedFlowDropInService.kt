package com.adyen.adyen_checkout.dropInAdvancedFlow


import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.lifecycle.ServiceLifecycleDispatcher
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.utils.Event
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.dropin.DropInService
import com.adyen.checkout.dropin.DropInServiceResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

//We should discuss if we can use LifecycleService instead of Service
class AdvancedFlowDropInService : DropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)
    private val dropInServiceResultHandler = DropInServiceResultHandler(this.lifecycleScope)

    override fun onSubmit(state: PaymentComponentState<*>) {
        try {
            setAdvancedFlowDropInServiceObserver()
            val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
            DropInServiceResultMessenger.sendResult(paymentComponentJson)
        } catch (exception: Exception) {
            Log.e("AdyenCheckout", "Exception occurred: $exception")
            sendResult(DropInServiceResult.Error(errorMessage = exception.message))
        }
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        try {
            setAdvancedFlowDropInAdditionalDetailsObserver()
            val actionComponentJson = ActionComponentData.SERIALIZER.serialize(actionComponentData)
            DropInAdditionalDetailsPlatformMessenger.sendResult(actionComponentJson)
        } catch (exception: Exception) {
            Log.e("AdyenCheckoutTest", "Exception occurred: $exception")
            sendResult(DropInServiceResult.Error(errorMessage = exception.message))
        }
    }

    private fun setAdvancedFlowDropInServiceObserver() {
        DropInPaymentResultMessenger.instance().removeObservers(this)
        DropInPaymentResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val result = dropInServiceResultHandler.handleResponse(message.contentIfNotHandled)
                ?: return@observe
            sendResult(result)
        }
    }

    private fun setAdvancedFlowDropInAdditionalDetailsObserver() {
        DropInAdditionalDetailsResultMessenger.instance().removeObservers(this)
        DropInAdditionalDetailsResultMessenger.instance().observe(this) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val result = dropInServiceResultHandler.handleResponse(message.contentIfNotHandled)
                ?: return@observe
            sendResult(result)
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