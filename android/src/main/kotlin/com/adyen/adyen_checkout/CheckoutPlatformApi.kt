package com.adyen.adyen_checkout

import CheckoutFlutterApi
import CheckoutPlatformInterface
import Configuration
import DropInResult
import DropInResultType
import PlatformCommunicationModel
import PlatformCommunicationType
import Session
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.dropInAdvancedFlow.AdvancedFlowDropInService
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInAdditionalDetailsPlatformMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInAdditionalDetailsResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInServiceResultMessenger
import com.adyen.adyen_checkout.utils.Constants.Companion.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import com.adyen.adyen_checkout.utils.Mapper.mapToDropInConfiguration
import com.adyen.adyen_checkout.utils.Mapper.mapToSession
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
class CheckoutPlatformApi(private val checkoutFlutterApi: CheckoutFlutterApi?) :
    CheckoutPlatformInterface {
    lateinit var activity: FragmentActivity
    lateinit var dropInSessionLauncher: ActivityResultLauncher<SessionDropInResultContractParams>
    lateinit var dropInAdvancedFlowLauncher: ActivityResultLauncher<DropInResultContractParams>

    override fun getPlatformVersion(callback: (Result<String>) -> Unit) {
        callback.invoke(Result.success("Android ${android.os.Build.VERSION.RELEASE}"))
    }

    override fun getReturnUrl(callback: (Result<String>) -> Unit) {
        callback(Result.success(RedirectComponent.getReturnUrl(activity.applicationContext)))
    }

    override fun startDropInSessionPayment(
        dropInConfiguration: Configuration,
        session: Session,
    ) {
        checkForFlutterFragmentActivity()
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val sessionModel = session.mapToSession()
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

    override fun startDropInAdvancedFlowPayment(
        dropInConfiguration: Configuration,
        paymentMethodsResponse: String,
    ) {
        checkForFlutterFragmentActivity()
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

    override fun onPaymentsResult(paymentsResult: DropInResult) {
        if (paymentsResult.dropInResultType == DropInResultType.ACTION) {
            setAdvanceFlowDropInAdditionalDetailsMessengerObserver()
        }

        DropInPaymentResultMessenger.sendResult(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: DropInResult) {
        DropInAdditionalDetailsResultMessenger.sendResult(paymentsDetailsResult)
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
        DropInServiceResultMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val model = PlatformCommunicationModel(
                PlatformCommunicationType.PAYMENTCOMPONENT,
                data = message.contentIfNotHandled.toString()
            )
            checkoutFlutterApi?.onDropInAdvancedFlowPlatformCommunication(model) {}
        }
    }

    private fun setAdvanceFlowDropInAdditionalDetailsMessengerObserver() {
        DropInAdditionalDetailsPlatformMessenger.instance().removeObservers(activity)
        DropInAdditionalDetailsPlatformMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val model = PlatformCommunicationModel(
                PlatformCommunicationType.ADDITIONALDETAILS,
                data = message.contentIfNotHandled.toString()
            )
            checkoutFlutterApi?.onDropInAdvancedFlowPlatformCommunication(model) {}
        }
    }

    private fun checkForFlutterFragmentActivity() {
        if (!this::activity.isInitialized) {
            throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        }
    }

}