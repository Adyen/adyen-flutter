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
    lateinit var googlePaySessionComponent: GooglePaySessionComponent
    private lateinit var componentFlutterInterface: ComponentFlutterInterface
    private lateinit var sessionHolder: SessionHolder

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
            InstantPaymentType.GOOGLEPAY -> googlePaySessionComponent.startGooglePayScreen()
            InstantPaymentType.APPLEPAY -> return
        }
    }

    override fun onDispose() {
        googlePaySessionComponent.dispose()
    }

    fun init(
        binding: ActivityPluginBinding,
        sessionHolder: SessionHolder,
        componentFlutterInterface: ComponentFlutterInterface
    ) {
        this.activity = binding.activity as FragmentActivity
        this.sessionHolder = sessionHolder
        this.componentFlutterInterface = componentFlutterInterface
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
            googlePaySessionComponent.checkGooglePayAvailability(paymentMethod, instantPaymentComponentConfigurationDTO)
            googlePaySessionComponent.googlePayAvailableFlow.collectLatest {
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
