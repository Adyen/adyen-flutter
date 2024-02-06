package com.adyen.checkout.flutter.components.googlepay

import AnalyticsOptionsDTO
import ComponentFlutterInterface
import InstantPaymentComponentConfigurationDTO
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.AnalyticsConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.redirect.RedirectComponent
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.Locale
import java.util.UUID

class GooglePaySessionComponent(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterApi: ComponentFlutterInterface,
) : ComponentAvailableCallback {
    val googlePayAvailableFlow = MutableStateFlow<Boolean?>(null)
    private lateinit var googlePayConfiguration: GooglePayConfiguration
    private lateinit var googlePayComponent: GooglePayComponent

    private val intentListener = Consumer<Intent> { handleIntent(it) }

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO,
    ) {
        activity.lifecycleScope.launch {
            if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
                googlePayAvailableFlow.emit(false)
            }

            googlePayConfiguration = mapToGooglePayConfiguration(instantPaymentComponentConfigurationDTO)
            GooglePayComponent.PROVIDER.isAvailable(
                activity.application,
                paymentMethod,
                googlePayConfiguration,
                this@GooglePaySessionComponent,
            )

        }
    }

    fun startGooglePayScreen() {
        googlePayComponent.startGooglePayScreen(activity, Constants.GOOGLE_PAY_REQUEST_CODE)
    }

    fun handleActivityResult(resultCode: Int, data: Intent?) {
        googlePayComponent.handleActivityResult(resultCode, data)
    }

    override fun onAvailabilityResult(isAvailable: Boolean, paymentMethod: PaymentMethod) {
        activity.lifecycleScope.launch {
            if (isAvailable) {
                setupGooglePayComponent(paymentMethod)
            }
            googlePayAvailableFlow.emit(isAvailable)
        }
    }

    private fun mapToGooglePayConfiguration(instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO): GooglePayConfiguration {
        val googlePayConfigurationBuilder: GooglePayConfiguration.Builder =
            if (instantPaymentComponentConfigurationDTO.shopperLocale != null) {
                val locale = Locale.forLanguageTag(instantPaymentComponentConfigurationDTO.shopperLocale)
                GooglePayConfiguration.Builder(
                    locale,
                    instantPaymentComponentConfigurationDTO.environment.toNativeModel(),
                    instantPaymentComponentConfigurationDTO.clientKey
                )
            } else {
                GooglePayConfiguration.Builder(
                    activity,
                    instantPaymentComponentConfigurationDTO.environment.toNativeModel(),
                    instantPaymentComponentConfigurationDTO.clientKey
                )
            }
        val analyticsConfiguration: AnalyticsConfiguration =
            instantPaymentComponentConfigurationDTO.analyticsOptionsDTO.mapToAnalyticsConfiguration()
        val amount: Amount = instantPaymentComponentConfigurationDTO.amount.toNativeModel()
        val countryCode: String = instantPaymentComponentConfigurationDTO.countryCode

        return instantPaymentComponentConfigurationDTO.googlePayConfigurationDTO?.mapToGooglePayConfiguration(
            googlePayConfigurationBuilder,
            analyticsConfiguration,
            amount,
            countryCode
        ) ?: throw Exception("Unable to create Google pay configuration")
    }

    private fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession = CheckoutSession(sessionSetupResponse = sessionSetupResponse, order = order)

        googlePayComponent = GooglePayComponent.PROVIDER.get(
            activity,
            checkoutSession,
            paymentMethod,
            googlePayConfiguration,
            GooglePaySessionCallback(componentFlutterApi) { action -> onAction(action) },
            UUID.randomUUID().toString()
        )

        googlePayComponent.getGooglePayButtonParameters().allowedPaymentMethods
    }

    private fun onAction(action: Action) = googlePayComponent.handleAction(action, activity)

    private fun handleIntent(intent: Intent) {
        if (intent.data?.toString().orEmpty().startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)) {
            googlePayComponent.handleIntent(intent)
        }
    }
}
