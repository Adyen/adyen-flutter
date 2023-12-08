package com.adyen.adyen_checkout

import CardComponentConfigurationDTO
import CheckoutFlutterApi
import CheckoutPlatformInterface
import DeletedStoredPaymentMethodResultDTO
import DropInConfigurationDTO
import PaymentFlowOutcomeDTO
import PaymentFlowResultType
import PlatformCommunicationModel
import PlatformCommunicationType
import SessionDTO
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.dropInAdvancedFlow.AdvancedFlowDropInService
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInAdditionalDetailsPlatformMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInAdditionalDetailsResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentMethodDeletionPlatformMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentMethodDeletionResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInPaymentResultMessenger
import com.adyen.adyen_checkout.dropInAdvancedFlow.DropInServiceResultMessenger
import com.adyen.adyen_checkout.dropInSession.SessionDropInService
import com.adyen.adyen_checkout.models.DropInFlowType
import com.adyen.adyen_checkout.session.SessionHolder
import com.adyen.adyen_checkout.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.adyen_checkout.utils.ConfigurationMapper.mapToDropInConfiguration
import com.adyen.adyen_checkout.utils.ConfigurationMapper.mapToSession
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.adyen_checkout.utils.Constants.Companion.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import com.adyen.checkout.components.core.OrderRequest
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.internal.Configuration
import com.adyen.checkout.core.AdyenLogger
import com.adyen.checkout.core.internal.util.Logger.NONE
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.internal.ui.model.DropInResultContractParams
import com.adyen.checkout.dropin.internal.ui.model.SessionDropInResultContractParams
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.sessions.core.SessionSetupResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

@Suppress("NAME_SHADOWING")
class CheckoutPlatformApi(
    private val checkoutFlutterApi: CheckoutFlutterApi?,
    private val sessionHolder: SessionHolder,
) : CheckoutPlatformInterface {
    lateinit var activity: FragmentActivity
    lateinit var dropInSessionLauncher: ActivityResultLauncher<SessionDropInResultContractParams>
    lateinit var dropInAdvancedFlowLauncher: ActivityResultLauncher<DropInResultContractParams>

    override fun getReturnUrl(callback: (Result<String>) -> Unit) {
        callback(Result.success(RedirectComponent.getReturnUrl(activity.applicationContext)))
    }

    override fun createSession(
        sessionId: String, sessionData: String,
        configuration: Any?,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val sessionModel = SessionModel(sessionId, sessionData)
            determineSessionConfiguration(configuration)?.let { sessionConfiguration ->
                when (val sessionResult = CheckoutSessionProvider.createSession(sessionModel, sessionConfiguration)) {
                    is CheckoutSessionResult.Error -> callback(Result.failure(sessionResult.exception))
                    is CheckoutSessionResult.Success -> onSessionSuccessfullyCreated(
                        sessionResult, sessionModel, callback
                    )
                }
            }
        }
    }


    private fun determineSessionConfiguration(configuration: Any?): Configuration? {
        when (configuration) {
            is CardComponentConfigurationDTO -> {
                return configuration.cardConfiguration.toNativeModel(
                    "${configuration.shopperLocale}",
                    activity,
                    configuration.environment.toNativeModel(),
                    configuration.clientKey,
                    configuration.analyticsOptionsDTO.mapToAnalyticsConfiguration(),
                    configuration.amount.toNativeModel()
                )
            }

            is DropInConfigurationDTO -> {
                //TODO: Add support for DropIn session
            }
        }

        return null
    }

    private fun onSessionSuccessfullyCreated(
        sessionResult: CheckoutSessionResult.Success,
        sessionModel: SessionModel,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
        with(sessionResult.checkoutSession) {
            val sessionResponse = SessionSetupResponse.SERIALIZER.serialize(sessionSetupResponse)
            val orderResponse = order?.let { OrderRequest.SERIALIZER.serialize(it) }
            val paymentMethodsJsonObject = sessionSetupResponse.paymentMethodsApiResponse?.let {
                PaymentMethodsApiResponse.SERIALIZER.serialize(it)
            }
            sessionHolder.sessionSetupResponse = sessionResponse
            sessionHolder.orderResponse = orderResponse
            callback(
                Result.success(
                    SessionDTO(
                        id = sessionModel.id,
                        sessionData = sessionModel.sessionData ?: "",
                        paymentMethodsJson = paymentMethodsJsonObject?.toString() ?: "",
                    )
                )
            )
        }
    }


    override fun startDropInSessionPayment(
        dropInConfigurationDTO: DropInConfigurationDTO,
        session: SessionDTO,
    ) {
        checkForFlutterFragmentActivity()
        setStoredPaymentMethodDeletionObserver()
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val sessionModel = session.mapToSession()
            val dropInConfiguration = dropInConfigurationDTO.mapToDropInConfiguration(activity.applicationContext)
            val checkoutSession = createCheckoutSession(sessionModel, dropInConfiguration)
            withContext(Dispatchers.Main) {
                DropIn.startPayment(
                    activity.applicationContext,
                    dropInSessionLauncher,
                    checkoutSession,
                    dropInConfiguration,
                    SessionDropInService::class.java
                )
            }
        }
    }

    override fun startDropInAdvancedFlowPayment(
        dropInConfigurationDTO: DropInConfigurationDTO,
        paymentMethodsResponse: String,
    ) {
        checkForFlutterFragmentActivity()
        setAdvancedFlowDropInServiceObserver()
        setStoredPaymentMethodDeletionObserver()
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(
                JSONObject(paymentMethodsResponse),
            )
            val paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethodsApiResponse)
            val dropInConfiguration = dropInConfigurationDTO.mapToDropInConfiguration(activity.applicationContext)
            withContext(Dispatchers.Main) {
                DropIn.startPayment(
                    activity.applicationContext,
                    dropInAdvancedFlowLauncher,
                    paymentMethodsWithoutGiftCards,
                    dropInConfiguration,
                    AdvancedFlowDropInService::class.java,
                )
            }
        }
    }

    override fun onPaymentsResult(paymentsResult: PaymentFlowOutcomeDTO) {
        if (paymentsResult.paymentFlowResultType == PaymentFlowResultType.ACTION) {
            setAdvanceFlowDropInAdditionalDetailsMessengerObserver()
        }

        DropInPaymentResultMessenger.sendResult(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentFlowOutcomeDTO) {
        DropInAdditionalDetailsResultMessenger.sendResult(paymentsDetailsResult)
    }

    override fun onDeleteStoredPaymentMethodResult(
        deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO
    ) {
        DropInPaymentMethodDeletionResultMessenger.sendResult(deleteStoredPaymentMethodResultDTO)
    }

    override fun enableConsoleLogging(loggingEnabled: Boolean) {
        if (loggingEnabled) {
            AdyenLogger.setLogLevel(Log.VERBOSE)
        } else {
            AdyenLogger.setLogLevel(NONE)
        }
    }

    override fun cleanUpDropIn() {
        DropInServiceResultMessenger.instance().removeObservers(activity)
        DropInPaymentMethodDeletionPlatformMessenger.instance().removeObservers(activity)
        DropInAdditionalDetailsPlatformMessenger.instance().removeObservers(activity)
    }

    private suspend fun createCheckoutSession(
        sessionModel: SessionModel,
        dropInConfiguration: com.adyen.checkout.dropin.DropInConfiguration,
    ): CheckoutSession {
        return when (val checkoutSessionResult =
            CheckoutSessionProvider.createSession(sessionModel, dropInConfiguration)) {
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
                data = message.contentIfNotHandled.toString(),
            )
            checkoutFlutterApi?.onDropInAdvancedFlowPlatformCommunication(model) {}
        }
    }

    private fun setStoredPaymentMethodDeletionObserver() {
        DropInPaymentMethodDeletionPlatformMessenger.instance().removeObservers(activity)
        DropInPaymentMethodDeletionPlatformMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val dropInStoredPaymentMethodDeletionModel = message.contentIfNotHandled
            val platformCommunicationModel = PlatformCommunicationModel(
                PlatformCommunicationType.DELETESTOREDPAYMENTMETHOD,
                data = dropInStoredPaymentMethodDeletionModel?.storedPaymentMethodId,
            )

            when (dropInStoredPaymentMethodDeletionModel?.dropInFlowType) {
                DropInFlowType.SESSION -> checkoutFlutterApi?.onDropInSessionPlatformCommunication(
                    platformCommunicationModel
                ) {}

                DropInFlowType.ADVANCED_FLOW -> checkoutFlutterApi?.onDropInAdvancedFlowPlatformCommunication(
                    platformCommunicationModel
                ) {}

                null -> return@observe
            }
        }
    }

    private fun setAdvanceFlowDropInAdditionalDetailsMessengerObserver() {
        DropInAdditionalDetailsPlatformMessenger.instance().removeObservers(activity)
        DropInAdditionalDetailsPlatformMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val platformCommunicationModel = PlatformCommunicationModel(
                PlatformCommunicationType.ADDITIONALDETAILS,
                data = message.contentIfNotHandled.toString(),
            )

            checkoutFlutterApi?.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel) {}
        }
    }

    private fun checkForFlutterFragmentActivity() {
        if (!this::activity.isInitialized) {
            throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        }
    }

    // Gift cards will be supported in a later version
    private fun removeGiftCardPaymentMethods(
        paymentMethodsResponse: PaymentMethodsApiResponse
    ): PaymentMethodsApiResponse {
        val giftCardTypeIdentifier = "giftcard"
        val storedPaymentMethods =
            paymentMethodsResponse.storedPaymentMethods?.filterNot { it.type == giftCardTypeIdentifier }
        val paymentMethods = paymentMethodsResponse.paymentMethods?.filterNot { it.type == giftCardTypeIdentifier }

        return PaymentMethodsApiResponse(
            storedPaymentMethods = storedPaymentMethods, paymentMethods = paymentMethods
        )
    }
}
