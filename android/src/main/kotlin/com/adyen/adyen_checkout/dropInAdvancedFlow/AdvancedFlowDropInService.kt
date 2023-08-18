package com.adyen.adyen_checkout.dropInAdvancedFlow


import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.lifecycle.ServiceLifecycleDispatcher
import androidx.lifecycle.lifecycleScope
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
    private var dropInPaymentsObserver: Observer<JSONObject>? = null
    private var dropInAdditionalDetailsObserver: Observer<JSONObject>? = null
    private val dropInServiceResultHandler = DropInServiceResultHandler(this.lifecycleScope)

    override fun onSubmit(state: PaymentComponentState<*>) {
        setAdvancedFlowDropInServiceObserver()

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
                DropInServiceResultMessenger.sendResult(paymentComponentJson)

            } catch (exception: Exception) {
                Log.e("AdyenCheckout", "Exception occurred: $exception")
                sendResult(DropInServiceResult.Error())
            }
        }
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        setAdvancedFlowDropInAdditionalDataObserver()

        lifecycleScope.launch(Dispatchers.IO) {
            try {
                val actionComponentJson = ActionComponentData.SERIALIZER.serialize(actionComponentData)
                DropInAdditionalDetailsResultMessenger.sendResult(actionComponentJson)

            } catch (exception: Exception) {
                Log.e("AdyenCheckoutTest", "Exception occurred: $exception")
                sendResult(DropInServiceResult.Error())
            }
        }
    }

    private fun setAdvancedFlowDropInServiceObserver() {
        dropInPaymentsObserver = Observer { message ->
            val result = dropInServiceResultHandler.handleResponse(message) ?: return@Observer
            sendResult(result)
            DropInPaymentResultMessenger.instance().removeObservers(this)
        }

        dropInPaymentsObserver?.let {
            DropInPaymentResultMessenger.instance().observe(this, it)
        }
    }

    private fun setAdvancedFlowDropInAdditionalDataObserver() {
        dropInAdditionalDetailsObserver = Observer { message ->
            val result = dropInServiceResultHandler.handleResponse(message) ?: return@Observer
            sendResult(result)
            DropInPaymentResultMessenger.instance().removeObservers(this)
        }

        dropInPaymentsObserver?.let {
            DropInAdditionalDetailsResultMessenger.instance().observe(this, it)
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