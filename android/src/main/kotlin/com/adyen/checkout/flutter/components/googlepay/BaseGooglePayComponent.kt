package com.adyen.checkout.flutter.components.googlepay

import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.redirect.RedirectComponent

abstract class BaseGooglePayComponent(
    private val activity: FragmentActivity,
    open val componentId: String,
) {
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    internal var googlePayComponent: GooglePayComponent? = null

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    abstract fun setupGooglePayComponent(paymentMethod: PaymentMethod)

    abstract fun startGooglePayScreen()

    abstract fun dispose()

    fun clear() {
        activity.removeOnNewIntentListener(intentListener)
        googlePayComponent = null
    }

    fun handleActivityResult(
        resultCode: Int,
        data: Intent?
    ) {
        googlePayComponent?.handleActivityResult(resultCode, data)
    }

    fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    private fun handleIntent(intent: Intent) {
        if (intent.data != null &&
            intent.data?.toString().orEmpty()
                .startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)
        ) {
            googlePayComponent?.handleIntent(intent)
        }
    }
}
