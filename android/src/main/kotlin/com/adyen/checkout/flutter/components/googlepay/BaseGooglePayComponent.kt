package com.adyen.checkout.flutter.components.googlepay

import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import InstantPaymentType
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.AnalyticsConfiguration
import com.adyen.checkout.components.core.ComponentAvailableCallback
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToAnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.redirect.RedirectComponent
import com.google.android.material.bottomsheet.BottomSheetDialogFragment
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.util.Locale

abstract class BaseGooglePayComponent(
    private val instantPaymentType: InstantPaymentType,
    private val activity: FragmentActivity,
    open val componentId: String,
) {
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    internal var googlePayComponent: GooglePayComponent? = null

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    abstract fun setupGooglePayComponent(paymentMethod: PaymentMethod): GooglePayComponent

    abstract fun startGooglePayScreen()

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

    private fun handleIntent(intent: Intent) {
        if (intent.data?.toString().orEmpty().startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)) {
            googlePayComponent?.handleIntent(intent)
        }
    }

    fun hideLoadingBottomSheet() {
        activity.supportFragmentManager.findFragmentByTag(ComponentLoadingBottomSheet.TAG)?.let {
            (it as? BottomSheetDialogFragment)?.dismiss()
        }
    }


}
