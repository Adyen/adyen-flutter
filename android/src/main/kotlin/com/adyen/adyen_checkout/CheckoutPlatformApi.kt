package com.adyen.adyen_checkout

import CheckoutPlatformInterface
import CheckoutResultFlutterInterface
import DropInConfigurationModel
import SessionModel
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Observer
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.Mapper.mapToDropInConfiguration
import com.adyen.adyen_checkout.Mapper.mapToSessionModel
import com.adyen.adyen_checkout.dropInAdvancedFlow.AdvancedFlowDropInService
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInAdditionalDetailsResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInServiceResultMessenger
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.internal.ui.model.DropInResultContractParams
import com.adyen.checkout.dropin.internal.ui.model.SessionDropInResultContractParams
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

@Suppress("NAME_SHADOWING")
class CheckoutPlatformApi(val checkoutResultFlutterInterface: CheckoutResultFlutterInterface) :
    CheckoutPlatformInterface {
    lateinit var activity: FragmentActivity
    lateinit var dropInSessionLauncher: ActivityResultLauncher<SessionDropInResultContractParams>
    lateinit var dropInAdvancedFlowLauncher: ActivityResultLauncher<DropInResultContractParams>

    private var advancedFlowDropInAdditionalDetailsObserver: Observer<JSONObject>? = null

    override fun getPlatformVersion(callback: (Result<String>) -> Unit) {
        callback.invoke(Result.success("Android ${android.os.Build.VERSION.RELEASE}"))
    }

    override fun startPayment(
        sessionModel: SessionModel,
        dropInConfiguration: DropInConfigurationModel,
        callback: (Result<Unit>) -> Unit
    ) {
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val sessionModel = sessionModel.mapToSessionModel()
            val dropInConfiguration =
                dropInConfiguration.mapToDropInConfiguration(activity.applicationContext)
            val checkoutSession = createCheckoutSession(sessionModel, dropInConfiguration)
            withContext(Dispatchers.Main) {
                DropIn.startPayment(
                    activity.applicationContext,
                    dropInSessionLauncher,
                    checkoutSession,
                    dropInConfiguration
                )
            }
        }

    }

    override fun startPaymentDropInAdvancedFlow(
        paymentMethodsResponse: String,
        dropInConfiguration: DropInConfigurationModel,
        callback: (Result<Unit>) -> Unit
    ) {
        setAdvancedFlowDropInServiceObserver()
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(
                JSONObject(paymentMethodsResponse)
            )
            val dropInConfiguration =
                dropInConfiguration.mapToDropInConfiguration(activity.applicationContext)
            withContext(Dispatchers.Main) {
                DropIn.startPayment(
                    activity.applicationContext,
                    dropInAdvancedFlowLauncher,
                    paymentMethodsApiResponse,
                    dropInConfiguration,
                    AdvancedFlowDropInService::class.java,
                )
            }
        }
    }

    override fun onPaymentsResult(
        paymentsResult: Map<String, Any?>,
        callback: (Result<String?>) -> Unit
    ) {
        val paymentsResultJson = JSONObject(paymentsResult)
        if (paymentsResultJson.has("action")) {
            setAdvanceFlowDropInAdditionalDetailsMessengerObserver(callback)
        } else {
            callback(Result.success(null))
        }
        DropInPaymentResultMessenger.sendResult(paymentsResultJson)
    }

    override fun onPaymentsDetailsResult(
        paymentsDetailsResult: Map<String, Any?>,
        callback: (Result<Unit>) -> Unit
    ) {
        DropInAdditionalDetailsResultMessenger.sendResult(JSONObject(paymentsDetailsResult))
    }

    override fun getReturnUrl(): String {
        return RedirectComponent.getReturnUrl(activity.applicationContext)
    }

    private suspend fun createCheckoutSession(
        sessionModel: com.adyen.checkout.sessions.core.SessionModel,
        dropInConfiguration: com.adyen.checkout.dropin.DropInConfiguration
    ): CheckoutSession {
        val checkoutSessionResult =
            CheckoutSessionProvider.createSession(sessionModel, dropInConfiguration)
        return when (checkoutSessionResult) {
            is CheckoutSessionResult.Success -> checkoutSessionResult.checkoutSession
            is CheckoutSessionResult.Error -> throw checkoutSessionResult.exception
        }
    }


    private fun setAdvancedFlowDropInServiceObserver() {
        DropInServiceResultMessenger.instance().removeObservers(activity)
        DropInServiceResultMessenger.instance().observe(activity, Observer { message ->
            if (message.hasBeenHandled()) {
                return@Observer
            }

            checkoutResultFlutterInterface.onDropInAdvancedFlowPaymentComponent(message.contentIfNotHandled.toString()) {}
        })

    }

    private fun setAdvanceFlowDropInAdditionalDetailsMessengerObserver(callback: (Result<String?>) -> Unit) {
        advancedFlowDropInAdditionalDetailsObserver = Observer { message ->
            callback.invoke(Result.success(message.toString()))

            DropInAdditionalDetailsResultMessenger.instance().removeObserver(advancedFlowDropInAdditionalDetailsObserver!!)
        }

        advancedFlowDropInAdditionalDetailsObserver?.let {
            DropInAdditionalDetailsResultMessenger.instance().observe(activity, it)
        }
    }

}