package com.adyen.checkout.flutter.components.instant

import ComponentCommunicationModel
import ComponentFlutterInterface
import ErrorDTO
import InstantPaymentConfigurationDTO
import InstantPaymentSetupResultDTO
import PaymentEventDTO
import PaymentResultDTO
import PaymentResultModelDTO
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.googlepay.advanced.GooglePayAdvancedComponentWrapper
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionCallback
import com.adyen.checkout.flutter.components.googlepay.session.GooglePaySessionComponentWrapper
import com.adyen.checkout.flutter.components.instant.advanced.InstantComponentAdvancedCallback
import com.adyen.checkout.flutter.components.instant.session.InstantComponentSessionCallback
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToGooglePayConfiguration
import com.adyen.checkout.flutter.utils.Constants
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.instant.InstantPaymentComponent
import com.adyen.checkout.instant.InstantPaymentConfiguration
import com.adyen.checkout.redirect.RedirectComponent
import org.json.JSONObject

class InstantComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
) {
    private var instantPaymentComponent: InstantPaymentComponent? = null
    private val intentListener = Consumer<Intent> { handleIntent(it) }

    init {
        activity.addOnNewIntentListener(intentListener)
    }

    fun startInstantPaymentComponent(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ) : InstantPaymentComponent {
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(JSONObject(paymentMethodResponse))
        val configuration = instantPaymentConfigurationDTO.fromDTO(activity)
        val instantPaymentComponent = createInstantPaymentComponent(configuration, paymentMethod, componentId)
        this.instantPaymentComponent = instantPaymentComponent
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, instantPaymentComponent)
        return instantPaymentComponent
    }

    private fun createInstantPaymentComponent(
        configuration: InstantPaymentConfiguration,
        paymentMethod: PaymentMethod,
        componentId: String,
    ): InstantPaymentComponent {
        return InstantPaymentComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            configuration = configuration,
            callback = InstantComponentAdvancedCallback(
                componentFlutterInterface,
                componentId,
                ::onLoading,
                ::hideLoadingBottomSheet
            ),
            key = componentId
        )
    }

    private fun onLoading(componentId: String) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId,
            )
        componentFlutterInterface.onComponentCommunication(model) {}
    }

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)

    fun onDispose() {

    }

    fun handlePaymentEvent(paymentEventDTO: PaymentEventDTO, componentId: String) {
        when (paymentEventDTO.paymentEventType) {
            PaymentEventType.FINISHED -> onFinished(paymentEventDTO.result, componentId)
            PaymentEventType.ACTION -> onAction(paymentEventDTO.actionResponse)
            PaymentEventType.ERROR -> onError(paymentEventDTO.error, componentId)
        }
    }

    private fun onFinished(resultCode: String?, componentId: String) {
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
        instantPaymentComponent?.handleAction(Action.SERIALIZER.deserialize(actionJson), activity)
    }

    private fun onError(error: ErrorDTO?, componentId: String) {
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


    private fun handleIntent(intent: Intent) {
        if (intent.data != null &&
            intent.data?.toString().orEmpty()
                .startsWith(RedirectComponent.REDIRECT_RESULT_SCHEME)
        ) {
            instantPaymentComponent?.handleIntent(intent)
        }
    }
}
