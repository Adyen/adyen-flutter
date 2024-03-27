package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import ErrorDTO
import PaymentEventDTO
import PaymentResultDTO
import PaymentResultModelDTO
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponentWrapper
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import org.json.JSONObject
import java.util.UUID

class GooglePayAdvancedComponentWrapper(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponentWrapper(activity, componentFlutterInterface) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        googlePayComponent =
            GooglePayComponent.PROVIDER.get(
                activity = activity,
                paymentMethod = paymentMethod,
                configuration = googlePayConfiguration,
                callback =
                    GooglePayAdvancedCallback(
                        componentFlutterInterface,
                        componentId,
                        ::onLoading,
                        ::hideLoadingBottomSheet
                    ),
                key = UUID.randomUUID().toString()
            )
    }

    fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error)
        }
    }

    private fun onFinished(resultCode: String?) {
        if (resultCode == null) {
            return
        }

        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult =
                    PaymentResultDTO(
                        type = PaymentResultEnum.FINISHED,
                        result = PaymentResultModelDTO(resultCode = resultCode)
                    ),
            )
        componentFlutterInterface.onComponentCommunication(model) {}
        hideLoadingBottomSheet()
    }

    private fun onAction(action: Map<String?, Any?>?) {
        if (action == null) {
            return
        }

        val actionJson = JSONObject(action)
        handleAction(Action.SERIALIZER.deserialize(actionJson))
    }

    private fun onError(error: ErrorDTO?) {
        if (error == null) {
            return
        }

        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult =
                    PaymentResultDTO(
                        type = PaymentResultEnum.ERROR,
                        reason = error.errorMessage,
                    ),
            )
        componentFlutterInterface.onComponentCommunication(model) {}
        hideLoadingBottomSheet()
    }
}
