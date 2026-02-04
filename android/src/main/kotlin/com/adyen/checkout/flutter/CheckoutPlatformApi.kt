package com.adyen.checkout.flutter

import android.annotation.SuppressLint
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.internal.Configuration
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.Checkout
import com.adyen.checkout.core.components.CheckoutConfiguration
import com.adyen.checkout.core.components.data.model.PaymentMethodsApiResponse
import com.adyen.checkout.core.old.AdyenLogLevel
import com.adyen.checkout.core.old.AdyenLogger
import com.adyen.checkout.flutter.apiOnly.AdyenCSE
import com.adyen.checkout.flutter.apiOnly.CardValidation
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardExpiryDateValidationResultDTO
import com.adyen.checkout.flutter.generated.CardNumberValidationResultDTO
import com.adyen.checkout.flutter.generated.CardSecurityCodeValidationResultDTO
import com.adyen.checkout.flutter.generated.CheckoutConfigurationDTO
import com.adyen.checkout.flutter.generated.CheckoutPlatformInterface
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.InstantPaymentType
import com.adyen.checkout.flutter.generated.SessionDTO
import com.adyen.checkout.flutter.generated.SessionResponseDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAmount
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToSessionResponse
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.flutter.utils.PlatformException
import com.adyen.checkout.redirect.old.RedirectComponent
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

    override fun setup(
        sessionResponseDTO: SessionResponseDTO,
        checkoutConfigurationDTO: CheckoutConfigurationDTO,
        callback: (Result<SessionDTO>) -> Unit
    ) {
        activity.lifecycleScope.launch(Dispatchers.IO) {
            try {
                val sessionResponse = sessionResponseDTO.mapToSessionResponse()
                val checkoutConfiguration = createConfiguration(checkoutConfigurationDTO)
                val checkoutResult = Checkout.setup(
                    sessionResponse,
                    checkoutConfiguration
                )

                when (checkoutResult) {
                    is Checkout.Result.Error -> onSetupError(
                        error = checkoutResult.errorReason,
                        callback = callback
                    )

                    is Checkout.Result.Success -> onSetupSuccess(
                        checkoutSession = checkoutResult.checkoutContext,
                        callback = callback
                    )
                }

            } catch (exception: Exception) {
                //Exception will contain the checkout error
                // TODO: Add error handling
                onSetupError(exception.message ?: "Checkout setup failed.", callback)
                return@launch
            }
        }
    }

    override fun createSession(
        sessionId: String,
        sessionData: String,
        configuration: Any?,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
//        activity.lifecycleScope.launch(Dispatchers.IO) {
//            val sessionModel = SessionModel(sessionId, sessionData)
//            determineSessionConfiguration(configuration)?.let { sessionConfiguration ->
//                when (val sessionResult = CheckoutSessionProvider.createSession(sessionModel=sessionModel, sessionConfiguration= sessionConfiguration)) {
//                    is CheckoutSessionResult.Error -> callback(Result.failure(sessionResult.exception))
//                    is CheckoutSessionResult.Success ->
//                        onSessionSuccessfullyCreated(
//                            sessionResult,
//                            sessionModel,
//                            callback
//                        )
//                }
//            }
//        }
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

    @SuppressLint("RestrictedApi")
    override fun enableConsoleLogging(loggingEnabled: Boolean) {
        if (loggingEnabled) {
            AdyenLogger.setLogLevel(AdyenLogLevel.VERBOSE)
        } else {
            AdyenLogger.setLogLevel(AdyenLogLevel.NONE)
        }
    }

    override fun getThreeDS2SdkVersion(): String = ThreeDS2Service.INSTANCE.sdkVersion

    private fun onSessionSuccessfullyCreated(
        sessionResult: CheckoutSessionResult.Success,
        sessionModel: SessionModel,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
        with(sessionResult.checkoutSession) {
            val sessionResponse = SessionSetupResponse.SERIALIZER.serialize(sessionSetupResponse)
            val paymentMethodsJsonObject =
                sessionSetupResponse.paymentMethodsApiResponse?.let {
                    com.adyen.checkout.components.core.PaymentMethodsApiResponse.SERIALIZER.serialize(it)
                }
            sessionHolder.sessionSetupResponse = sessionResponse
            callback(
                Result.success(
                    SessionDTO(
                        id = sessionModel.id,
                        paymentMethodsJson = paymentMethodsJsonObject?.toString() ?: "",
                    )
                )
            )
        }
    }

    private fun onSetupSuccess(
        checkoutSession: CheckoutContext.Sessions,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
        sessionHolder.sessionCheckout = checkoutSession
        val paymentMethodsJsonObject =
            checkoutSession.checkoutSession.sessionSetupResponse.paymentMethodsApiResponse?.let {
                PaymentMethodsApiResponse.SERIALIZER.serialize(it)
            }
        callback(
            Result.success(
                SessionDTO(
                    id = checkoutSession.checkoutSession.sessionSetupResponse.id,
                    paymentMethodsJson = paymentMethodsJsonObject?.toString() ?: "",
                )
            )
        )
    }

    private fun onSetupError(
        error: String,
        callback: (Result<SessionDTO>) -> Unit,
    ) {
        callback(Result.failure(PlatformException(error)))
    }

    private fun createConfiguration(configurationDTO: CheckoutConfigurationDTO): CheckoutConfiguration =
        configurationDTO.toCheckoutConfiguration()
}
