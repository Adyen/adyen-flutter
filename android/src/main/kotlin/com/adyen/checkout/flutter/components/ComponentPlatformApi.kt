package com.adyen.checkout.flutter.components

import ComponentFlutterInterface
import ComponentPlatformInterface
import ErrorDTO
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import InstantPaymentType
import PaymentEventDTO
import PaymentEventType
import PaymentResultModelDTO
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionComponent
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import org.json.JSONObject

class ComponentPlatformApi(
    private val activity: FragmentActivity,
    private val sessionHolder: SessionHolder,
    private val componentFlutterInterface: ComponentFlutterInterface,
) : ComponentPlatformInterface {
    private var googlePaySessionComponent: GooglePaySessionComponent? = null

    override fun updateViewHeight(viewId: Long) {
        ComponentHeightMessenger.sendResult(viewId)
    }

    override fun onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentsDetailsResult)
    }

    override fun isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        val paymentMethodJson = JSONObject(paymentMethodResponse)
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
        when (instantPaymentConfigurationDTO.instantPaymentType) {
            InstantPaymentType.GOOGLEPAY ->
                isGooglePaySupported(
                    paymentMethod,
                    instantPaymentConfigurationDTO,
                    componentId,
                    callback
                )

            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onInstantPaymentPressed(instantPaymentType: InstantPaymentType) {
        when (instantPaymentType) {
            InstantPaymentType.GOOGLEPAY -> googlePaySessionComponent?.startGooglePayScreen()
            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onDispose() {
        googlePaySessionComponent?.dispose()
        googlePaySessionComponent = null
    }

    fun handleActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean {
        return when (requestCode) {
            Constants.GOOGLE_PAY_REQUEST_CODE -> {
                googlePaySessionComponent?.handleActivityResult(resultCode, data)
                true
            }

            else -> false
        }
    }

    private fun isGooglePaySupported(
        paymentMethod: PaymentMethod,
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO>) -> Unit
    ) {
        activity.lifecycleScope.launch {
            googlePaySessionComponent =
                GooglePaySessionComponent(activity, sessionHolder, componentFlutterInterface, componentId)
            googlePaySessionComponent?.checkGooglePayAvailability(paymentMethod, instantPaymentComponentConfigurationDTO)
            googlePaySessionComponent?.googlePayAvailableFlow?.collectLatest {
                if (it?.isSupported == true) {
                    callback(Result.success(it))
                } else if (it?.isSupported == false) {
                    callback(Result.failure(Exception("Google pay not available")))
                }
            }
        }
    }

    private fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error)
        }
    }

    private fun onFinished(resultCode: String?) {
        val paymentResult = PaymentResultModelDTO(resultCode = resultCode)
        ComponentResultMessenger.sendResult(paymentResult)
    }

    private fun onAction(actionResponse: Map<String?, Any?>?) {
        actionResponse?.let {
            val jsonActionResponse = JSONObject(it)
            ComponentActionMessenger.sendResult(jsonActionResponse)
        }
    }

    private fun onError(error: ErrorDTO?) {
        error?.let {
            ComponentErrorMessenger.sendResult(it)
        }
    }
}
