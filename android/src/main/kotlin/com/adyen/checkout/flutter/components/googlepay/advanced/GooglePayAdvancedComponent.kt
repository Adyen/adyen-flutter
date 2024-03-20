package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import PaymentResultDTO
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.ComponentActionMessenger
import com.adyen.checkout.flutter.components.ComponentErrorMessenger
import com.adyen.checkout.flutter.components.ComponentResultMessenger
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponent
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_ADVANCED_REQUEST_CODE
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration

class GooglePayAdvancedComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponent(activity) {
    init {
        addActionListener()
        addResultListener()
        addErrorListener()
    }

    override fun setupGooglePayComponent(paymentMethod: PaymentMethod) {
        googlePayComponent =
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
        googlePayComponent?.startGooglePayScreen(activity, GOOGLE_PAY_ADVANCED_REQUEST_CODE)
    }

    override fun dispose() {
        ComponentActionMessenger.instance().removeObservers(activity)
        ComponentResultMessenger.instance().removeObservers(activity)
        clear()
    }

    private fun addActionListener() {
        ComponentActionMessenger.instance().removeObservers(activity)
        ComponentActionMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val action = message.contentIfNotHandled?.let { Action.SERIALIZER.deserialize(it) }
            action?.let {
                googlePayComponent?.apply {
                    this.handleAction(action = it, activity = activity)
                    ComponentLoadingBottomSheet.show(activity.supportFragmentManager, this)
                }
            }
        }
    }

    private fun addResultListener() {
        ComponentResultMessenger.instance().removeObservers(activity)
        ComponentResultMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val model =
                ComponentCommunicationModel(
                    ComponentCommunicationType.RESULT,
                    componentId = componentId,
                    paymentResult = PaymentResultDTO(
                        type = PaymentResultEnum.FINISHED,
                        result = message.contentIfNotHandled
                    ),
                )
            componentFlutterApi.onComponentCommunication(model) {}
            hideLoadingBottomSheet()
        }
    }

    private fun addErrorListener() {
        ComponentErrorMessenger.instance().removeObservers(activity)
        ComponentErrorMessenger.instance().observe(activity) { message ->
            if (message.hasBeenHandled()) {
                return@observe
            }

            val model =
                ComponentCommunicationModel(
                    ComponentCommunicationType.RESULT,
                    componentId = componentId,
                    paymentResult = PaymentResultDTO(
                        type = PaymentResultEnum.ERROR,
                        reason = message.contentIfNotHandled?.errorMessage,
                    ),
                )
            componentFlutterApi.onComponentCommunication(model) {}
        }
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
