package com.adyen.checkout.flutter

import CardComponentConfigurationDTO
import CheckoutPlatformInterface
import DropInConfigurationDTO
import SessionDTO
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.OrderRequest
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.components.core.internal.Configuration
import com.adyen.checkout.core.AdyenLogger
import com.adyen.checkout.core.internal.util.Logger.NONE
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToDropInConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.sessions.core.SessionSetupResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Suppress("NAME_SHADOWING")
class CheckoutPlatformApi(
    private val sessionHolder: SessionHolder,
) : CheckoutPlatformInterface {
    lateinit var activity: FragmentActivity

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

    private fun determineSessionConfiguration(configuration: Any?): Configuration? {
        when (configuration) {
            is CardComponentConfigurationDTO -> {
                return configuration.cardConfiguration.toNativeModel(
                    activity,
                    configuration.shopperLocale,
                    configuration.environment.toNativeModel(),
                    configuration.clientKey,
                    configuration.analyticsOptionsDTO.mapToAnalyticsConfiguration(),
                    configuration.amount.toNativeModel()
                )
            }

            is DropInConfigurationDTO -> {
                return configuration.mapToDropInConfiguration(activity)
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

    override fun enableConsoleLogging(loggingEnabled: Boolean) {
        if (loggingEnabled) {
            AdyenLogger.setLogLevel(Log.VERBOSE)
        } else {
            AdyenLogger.setLogLevel(NONE)
        }
    }
}
