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
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponent
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_ADVANCED_REQUEST_CODE
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import org.json.JSONObject

class GooglePayAdvancedComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponent(activity) {
    override fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        nativeGooglePayComponent =
            GooglePayComponent.PROVIDER.get(
                activity = activity,
                paymentMethod = paymentMethod,
                configuration = googlePayConfiguration,
                callback =
                    GooglePayAdvancedCallback(
                        componentFlutterApi,
                        componentId,
                        ::onLoading,
                        ::hideLoadingBottomSheet
                    ),
            )
    }

    override fun startGooglePayScreen() {
        nativeGooglePayComponent?.startGooglePayScreen(activity, GOOGLE_PAY_ADVANCED_REQUEST_CODE)
    }

    override fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error)
        }
    }

    override fun dispose() = clear()

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
        componentFlutterApi.onComponentCommunication(model) {}
        hideLoadingBottomSheet()
    }

    private fun onAction(action: Map<String?, Any?>?) {
        if (action == null) {
            return
        }

        action.let {
            nativeGooglePayComponent?.apply {
                val actionJson = JSONObject(action)
                this.handleAction(action = Action.SERIALIZER.deserialize(actionJson), activity = activity)
                ComponentLoadingBottomSheet.show(activity.supportFragmentManager, this)
            }
        }
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
        componentFlutterApi.onComponentCommunication(model) {}
        hideLoadingBottomSheet()
    }

    private fun onLoading() {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId,
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
