package com.adyen.checkout.flutter.components

import ComponentPlatformInterface
import ErrorDTO
import InstantPaymentComponentConfigurationDTO
import InstantPaymentType
import PaymentEventDTO
import PaymentEventType
import PaymentResultModelDTO
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.flutter.components.googlepay.GooglePaySessionComponent
import com.adyen.checkout.flutter.session.SessionHolder
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import org.json.JSONObject

class ComponentPlatformApi : ComponentPlatformInterface {
    lateinit var activity: FragmentActivity
    lateinit var sessionHolder: SessionHolder
    lateinit var googlePaySessionComponent: GooglePaySessionComponent
    override fun updateViewHeight(viewId: Long) {
        ComponentHeightMessenger.sendResult(viewId)
    }

    override fun onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentsResult)
    }

    override fun onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentsDetailsResult)
    }

    override fun isInstantPaymentMethodSupportedByPlatform(
        instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO,
        paymentMethodResponse: String,
        callback: (Result<Boolean>) -> Unit
    ) {
        val paymentMethodJson = JSONObject(paymentMethodResponse)
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(paymentMethodJson)
        when (instantPaymentComponentConfigurationDTO.instantPaymentType) {
            InstantPaymentType.GOOGLEPAY -> isGooglePaySupported(
                paymentMethod,
                instantPaymentComponentConfigurationDTO,
                callback
            )

            InstantPaymentType.APPLEPAY -> TODO()
        }
    }

    override fun onInstantPaymentMethodPressed(instantPaymentType: InstantPaymentType) {
        when (instantPaymentType) {
            InstantPaymentType.GOOGLEPAY -> googlePaySessionComponent.startGooglePayScreen()
            InstantPaymentType.APPLEPAY -> TODO()
        }
    }

    fun init(binding: ActivityPluginBinding, sessionHolder: SessionHolder) {
        this.activity = binding.activity as FragmentActivity
        this.sessionHolder = sessionHolder
        googlePaySessionComponent = GooglePaySessionComponent(activity, sessionHolder)
    }

    private fun isGooglePaySupported(
        paymentMethod: PaymentMethod,
        instantPaymentComponentConfigurationDTO: InstantPaymentComponentConfigurationDTO,
        callback: (Result<Boolean>) -> Unit
    ) {
        activity.lifecycleScope.launch {
            googlePaySessionComponent.checkGooglePayAvailability(paymentMethod, instantPaymentComponentConfigurationDTO)
            googlePaySessionComponent.googlePayAvailableFlow.collectLatest {
                if (it == true) {
                    callback(Result.success(true))
                } else if (it == false) {
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
