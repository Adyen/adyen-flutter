package com.adyen.adyen_checkout.dropInAdvancedFlow


import android.content.Intent
import android.util.Log
import androidx.annotation.CallSuper
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.lifecycle.ServiceLifecycleDispatcher
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentComponentState
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.dropin.DropInService
import com.adyen.checkout.dropin.DropInServiceResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject

//We should discuss if we can use LifecycleService
class AdvancedFlowDropInService : DropInService(), LifecycleOwner {
    private val dispatcher = ServiceLifecycleDispatcher(this)
    private var dropInPaymentObserver: Observer<JSONObject>? = null

    override fun onSubmit(state: PaymentComponentState<*>) {
        setAdvancedFlowDropInServiceObserver()

        launch(Dispatchers.IO) {
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
        launch(Dispatchers.IO) {
            try {
                val actionComponentJson =
                    ActionComponentData.SERIALIZER.serialize(actionComponentData)
                DropInServiceResultMessenger.sendResult(actionComponentJson)
            } catch (exception: Exception) {
                Log.e("AdyenCheckoutTest", "Exception occurred: $exception")
                sendResult(DropInServiceResult.Error())
            }
        }
    }


    private fun setAdvancedFlowDropInServiceObserver() {
        dropInPaymentObserver = Observer { message ->
            val resultCode = Action.SERIALIZER.deserialize(
                JSONObject(message.get("action").toString())
            )
            sendResult(DropInServiceResult.Action(resultCode))
            DropInPaymentResultMessenger.instance().removeObservers(this)
        }

        dropInPaymentObserver?.let {
            DropInPaymentResultMessenger.instance().observe(this, it)
        }
    }

    @CallSuper
    override fun onCreate() {
        dispatcher.onServicePreSuperOnCreate()
        super.onCreate()
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    @CallSuper
    override fun onStart(intent: Intent?, startId: Int) {
        dispatcher.onServicePreSuperOnStart()
        super.onStart(intent, startId)
    }


    @CallSuper
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return super.onStartCommand(intent, flags, startId)
    }

    @CallSuper
    override fun onDestroy() {
        dispatcher.onServicePreSuperOnDestroy()
        super.onDestroy()
    }

    override val lifecycle: Lifecycle
        get() = dispatcher.lifecycle
}