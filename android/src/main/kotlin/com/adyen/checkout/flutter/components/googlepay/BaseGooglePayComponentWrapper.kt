package com.adyen.checkout.flutter.components.googlepay

import ComponentCommunicationModel
import ComponentFlutterInterface
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent

abstract class BaseGooglePayComponentWrapper(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val componentId: String
) {
    internal var googlePayComponent: GooglePayComponent? = null

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

    fun onLoading() {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId,
            )
        componentFlutterInterface.onComponentCommunication(model) {}
    }

    fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    fun dispose(componentId: String) {
        if (componentId == this.componentId) {
            googlePayComponent = null
        }
    }
}
