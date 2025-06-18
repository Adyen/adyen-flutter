package com.adyen.checkout.flutter

import android.annotation.SuppressLint
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.OrderRequest
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.internal.Configuration
import com.adyen.checkout.core.old.AdyenLogLevel
import com.adyen.checkout.core.old.AdyenLogger
import com.adyen.checkout.flutter.apiOnly.AdyenCSE
import com.adyen.checkout.flutter.apiOnly.CardValidation
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardExpiryDateValidationResultDTO
import com.adyen.checkout.flutter.generated.CardNumberValidationResultDTO
import com.adyen.checkout.flutter.generated.CardSecurityCodeValidationResultDTO
import com.adyen.checkout.flutter.generated.CheckoutPlatformInterface
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.InstantPaymentType
import com.adyen.checkout.flutter.generated.SessionDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAmount
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCardConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToDropInConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.sessions.core.SessionSetupResponse
import com.adyen.threeds2.ThreeDS2Service
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class CheckoutPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
) : CheckoutPlatformInterface {
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

    override fun clearSession() {
        sessionHolder.reset()
    }

    override fun encryptCard(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String,
        callback: (Result<EncryptedCardDTO>) -> Unit
    ) {
        val encryptedCardResult = AdyenCSE.encryptCard(unencryptedCardDTO, publicKey)
        callback(encryptedCardResult)
    }

    override fun encryptBin(
        bin: String,
        publicKey: String,
        callback: (Result<String>) -> Unit
    ) {
        val encryptedBin = AdyenCSE.encryptBin(bin, publicKey)
        callback(encryptedBin)
    }

    override fun validateCardNumber(
        cardNumber: String,
        enableLuhnCheck: Boolean
    ): CardNumberValidationResultDTO = CardValidation.validateCardNumber(cardNumber, enableLuhnCheck)

    override fun validateCardExpiryDate(
        expiryMonth: String,
        expiryYear: String
    ): CardExpiryDateValidationResultDTO = CardValidation.validateCardExpiryDate(expiryMonth, expiryYear)

    override fun validateCardSecurityCode(
        securityCode: String,
        cardBrand: String?
    ): CardSecurityCodeValidationResultDTO = CardValidation.validateCardSecurityCode(securityCode, cardBrand)

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
                    InstantPaymentType.APPLE_PAY -> throw IllegalStateException(
                        "Apple Pay is not supported on Android."
                    )
                    InstantPaymentType.GOOGLE_PAY -> configuration.mapToCheckoutConfiguration()
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
            AdyenLogger.setLogLevel(AdyenLogLevel.VERBOSE)
        } else {
            AdyenLogger.setLogLevel(AdyenLogLevel.NONE)
        }
    }

    override fun getThreeDS2SdkVersion(): String = ThreeDS2Service.INSTANCE.sdkVersion
}
