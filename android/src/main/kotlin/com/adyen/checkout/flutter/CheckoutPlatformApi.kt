package com.adyen.checkout.flutter

import CardComponentConfigurationDTO
import CheckoutPlatformInterface
import DropInConfigurationDTO
import EncryptedCardDTO
import InstantPaymentConfigurationDTO
import SessionDTO
import UnencryptedCardDTO
import android.annotation.SuppressLint
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.OrderRequest
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.internal.Configuration
import com.adyen.checkout.core.AdyenLogger
import com.adyen.checkout.core.internal.util.Logger.NONE
import com.adyen.checkout.flutter.cse.AdyenCSE
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToDropInConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCardConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAmount
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.sessions.core.SessionSetupResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class CheckoutPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
) : CheckoutPlatformInterface {
    private val adyenCSE: AdyenCSE = AdyenCSE()

    override fun getReturnUrl(callback: (Result<String>) -> Unit) {
        callback(Result.success(RedirectComponent.getReturnUrl(activity.applicationContext)))
    }

    override fun createSession(
        sessionId: String,
        sessionData: String,
        configuration: Any?,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
        activity.lifecycleScope.launch(Dispatchers.IO) {
            val sessionModel = SessionModel(sessionId, sessionData)
            determineSessionConfiguration(configuration)?.let { sessionConfiguration ->
                when (val sessionResult = CheckoutSessionProvider.createSession(sessionModel, sessionConfiguration)) {
                    is CheckoutSessionResult.Error -> callback(Result.failure(sessionResult.exception))
                    is CheckoutSessionResult.Success ->
                        onSessionSuccessfullyCreated(
                            sessionResult,
                            sessionModel,
                            callback
                        )
                }
            }
        }
    }

    override fun encryptCard(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String,
        callback: (Result<EncryptedCardDTO>) -> Unit
    ) {
        val encryptedCardResult = adyenCSE.encryptCard(unencryptedCardDTO, publicKey)
        callback(encryptedCardResult)
    }

    override fun encryptBin(
        bin: String,
        publicKey: String,
        callback: (Result<String>) -> Unit
    ) {
        val encryptedBin = adyenCSE.encryptBin(bin, publicKey)
        callback(encryptedBin)
    }

    private fun determineSessionConfiguration(configuration: Any?): Configuration? {
        when (configuration) {
            is DropInConfigurationDTO -> {
                return configuration.mapToDropInConfiguration(activity)
            }

            is CardComponentConfigurationDTO -> {
                return configuration.cardConfiguration.mapToCardConfiguration(
                    activity,
                    configuration.shopperLocale,
                    configuration.environment.mapToEnvironment(),
                    configuration.clientKey,
                    configuration.analyticsOptionsDTO.mapToAnalyticsConfiguration(),
                    configuration.amount?.mapToAmount()
                )
            }

            is InstantPaymentConfigurationDTO -> {
                return when (configuration.instantPaymentType) {
                    InstantPaymentType.APPLEPAY -> throw IllegalStateException("Apple Pay is not supported on Android.")
                    InstantPaymentType.GOOGLEPAY -> configuration.mapToCheckoutConfiguration()
                    InstantPaymentType.INSTANT -> configuration.mapToCheckoutConfiguration()
                }
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
            val paymentMethodsJsonObject =
                sessionSetupResponse.paymentMethodsApiResponse?.let {
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

    @SuppressLint("RestrictedApi")
    override fun enableConsoleLogging(loggingEnabled: Boolean) {
        if (loggingEnabled) {
            AdyenLogger.setLogLevel(Log.VERBOSE)
        } else {
            AdyenLogger.setLogLevel(NONE)
        }
    }
}
