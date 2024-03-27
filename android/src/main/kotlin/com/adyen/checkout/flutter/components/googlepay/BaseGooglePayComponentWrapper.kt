package com.adyen.checkout.flutter.components.googlepay

import ComponentCommunicationModel
import ComponentFlutterInterface
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.redirect.RedirectComponent

abstract class BaseGooglePayComponentWrapper(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface
) {
    private val intentListener = Consumer<Intent> { handleIntent(it) }
    internal var googlePayComponent: GooglePayComponent? = null
    abstract val componentId: String

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    abstract fun setupGooglePayComponent(paymentMethod: PaymentMethod)

    fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen(activity, Constants.GOOGLE_PAY_COMPONENT_REQUEST_CODE)
    }

    fun handleActivityResult(
        resultCode: Int,
        data: Intent?
    ) {
        googlePayComponent?.handleActivityResult(resultCode, data)
    }

    fun handleAction(action: Action) {
        googlePayComponent?.let {
            it.handleAction(action, activity)
            ComponentLoadingBottomSheet.show(activity.supportFragmentManager, it)
        }
    }

    fun onLoading() {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId,
            )
        componentFlutterInterface.onComponentCommunication(model) {}
    }

    fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    fun dispose() {
        activity.removeOnNewIntentListener(intentListener)
        googlePayComponent = null
    }

    private fun handleIntent(intent: Intent) {
        if (intent.data != null &&
            intent.data?.toString().orEmpty()
                .startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)
        ) {
            googlePayComponent?.handleIntent(intent)
        }
    }
}
