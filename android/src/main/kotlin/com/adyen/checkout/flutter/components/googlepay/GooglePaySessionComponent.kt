package com.adyen.checkout.flutter.components.googlepay

import InstantPaymentComponentConfigurationDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayComponentState
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionComponentCallback
import com.adyen.checkout.sessions.core.SessionPaymentResult
import com.adyen.checkout.sessions.core.SessionSetupResponse
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.Locale
import java.util.UUID

class GooglePaySessionComponent(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
) : ComponentAvailableCallback, SessionComponentCallback<GooglePayComponentState> {
    val googlePayAvailableFlow = MutableStateFlow<Boolean?>(null)
    private lateinit var googlePayConfiguration: GooglePayConfiguration
    private lateinit var googlePayComponent: GooglePayComponent


    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO,
    ) {
        activity.lifecycleScope.launch {
            if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
                googlePayAvailableFlow.emit(false)
            }

            googlePayConfiguration = buildGooglePayConfiguration(instantPaymentComponentConfigurationDTO)
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

    private fun buildGooglePayConfiguration(instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO): GooglePayConfiguration {
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

        return instantPaymentComponentConfigurationDTO.googlePayConfigurationDTO?.mapToGooglePayConfiguration(
            googlePayConfigurationBuilder
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
            this,
            UUID.randomUUID().toString()
        )
    }

    override fun onAction(action: Action) {
        println("ON ACTION")
    }

    override fun onError(componentError: ComponentError) {
        println("ON ERROR")
    }

    override fun onFinished(result: SessionPaymentResult) {
        println("ON FINISHED ${result.resultCode}")
    }

}
