package com.adyen.checkout.flutter.components.googlepay

import PaymentEventDTO
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.redirect.RedirectComponent

abstract class BaseGooglePayComponent(
    private val activity: FragmentActivity,
) {
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    internal var nativeGooglePayComponent: GooglePayComponent? = null
    abstract val componentId: String

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    abstract fun setupGooglePayComponent(paymentMethod: PaymentMethod)

    abstract fun startGooglePayScreen()

    abstract fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO)

    abstract fun dispose()

    fun clear() {
        activity.removeOnNewIntentListener(intentListener)
        nativeGooglePayComponent = null
    }

    fun handleActivityResult(
        resultCode: Int,
        data: Intent?
    ) {
        nativeGooglePayComponent?.handleActivityResult(resultCode, data)
    }

    fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    private fun handleIntent(intent: Intent) {
        if (intent.data != null &&
            intent.data?.toString().orEmpty()
                .startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)
        ) {
            nativeGooglePayComponent?.handleIntent(intent)
        }
    }
}
