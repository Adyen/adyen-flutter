package com.adyen.checkout.flutter.components.googlepay

import ComponentFlutterInterface
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
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
import com.adyen.checkout.flutter.components.ComponentLoadingBottomSheet
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
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.Locale
import java.util.UUID

class GooglePaySessionComponent(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String,
) : ComponentAvailableCallback {
    private lateinit var googlePayConfiguration: GooglePayConfiguration
    private var googlePayComponent: GooglePayComponent? = null
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    val googlePayAvailableFlow = MutableStateFlow<InstantPaymentSetupResultDTO?>(null)

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    override fun onAvailabilityResult(
        isAvailable: Boolean,
        paymentMethod: PaymentMethod
    ) {
        activity.lifecycleScope.launch {
            if (isAvailable) {
                googlePayComponent = setupGooglePayComponent(paymentMethod)
            }

            val allowedPaymentMethods: String =
                googlePayComponent?.getGooglePayButtonParameters()?.allowedPaymentMethods ?: ""
            googlePayAvailableFlow.emit(
                InstantPaymentSetupResultDTO(InstantPaymentType.GOOGLEPAY, isAvailable, allowedPaymentMethods)
            )
        }
    }

    fun checkGooglePayAvailability(
        paymentMethod: PaymentMethod,
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
    ) {
        activity.lifecycleScope.launch {
            if (!GooglePayComponent.PROVIDER.isPaymentMethodSupported(paymentMethod)) {
                googlePayAvailableFlow.emit(
                    InstantPaymentSetupResultDTO(InstantPaymentType.GOOGLEPAY, false, emptyList<String>())
                )
            }

            googlePayConfiguration = mapToGooglePayConfiguration(instantPaymentConfigurationDTO)
            GooglePayComponent.PROVIDER.isAvailable(
                activity.application,
                paymentMethod,
                googlePayConfiguration,
                this@GooglePaySessionComponent,
            )
        }
    }

    fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen(activity, Constants.GOOGLE_PAY_REQUEST_CODE)
    }

    fun handleActivityResult(
        resultCode: Int,
        data: Intent?
    ) {
        googlePayComponent?.handleActivityResult(resultCode, data)
    }

    fun dispose() {
        activity.removeOnNewIntentListener(intentListener)
        googlePayComponent = null
    }

    private fun mapToGooglePayConfiguration(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO
    ): GooglePayConfiguration {
        val googlePayConfigurationBuilder: GooglePayConfiguration.Builder =
            if (instantPaymentConfigurationDTO.shopperLocale != null) {
                val locale = Locale.forLanguageTag(instantPaymentConfigurationDTO.shopperLocale)
                GooglePayConfiguration.Builder(
                    locale,
                    instantPaymentConfigurationDTO.environment.toNativeModel(),
                    instantPaymentConfigurationDTO.clientKey
                )
            } else {
                GooglePayConfiguration.Builder(
                    activity,
                    instantPaymentConfigurationDTO.environment.toNativeModel(),
                    instantPaymentConfigurationDTO.clientKey
                )
            }
        val analyticsConfiguration: AnalyticsConfiguration =
            instantPaymentConfigurationDTO.analyticsOptionsDTO.mapToAnalyticsConfiguration()
        val amount: Amount = instantPaymentConfigurationDTO.amount.toNativeModel()
        val countryCode: String = instantPaymentConfigurationDTO.countryCode

        return instantPaymentConfigurationDTO.googlePayConfigurationDTO?.mapToGooglePayConfiguration(
            googlePayConfigurationBuilder,
            analyticsConfiguration,
            amount,
            countryCode
        ) ?: throw Exception("Unable to create Google pay configuration")
    }

    private fun setupGooglePayComponent(paymentMethod: PaymentMethod): GooglePayComponent {
        val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionHolder.sessionSetupResponse)
        val order = sessionHolder.orderResponse?.let { Order.SERIALIZER.deserialize(it) }
        val checkoutSession = CheckoutSession(sessionSetupResponse = sessionSetupResponse, order = order)
        return GooglePayComponent.PROVIDER.get(
            activity,
            checkoutSession,
            paymentMethod,
            googlePayConfiguration,
            GooglePaySessionCallback(componentFlutterApi, componentId, ::onAction, ::hideLoadingBottomSheet),
            UUID.randomUUID().toString()
        )
    }

    private fun onAction(action: Action) {
        googlePayComponent?.apply {
            handleAction(action, activity)
            val loadingBottomSheet = ComponentLoadingBottomSheet(this)
            loadingBottomSheet.isCancelable = false
            loadingBottomSheet.show(activity.supportFragmentManager, ComponentLoadingBottomSheet.TAG)
        }
    }

    private fun handleIntent(intent: Intent) {
        if (intent.data?.toString().orEmpty().startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)) {
            googlePayComponent?.handleIntent(intent)
        }
    }

    private fun hideLoadingBottomSheet() {
        activity.supportFragmentManager.findFragmentByTag(ComponentLoadingBottomSheet.TAG)?.let {
            (it as? BottomSheetDialogFragment)?.dismiss()
        }
    }
}
