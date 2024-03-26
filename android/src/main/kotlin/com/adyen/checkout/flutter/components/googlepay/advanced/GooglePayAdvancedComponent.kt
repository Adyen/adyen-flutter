package com.adyen.checkout.flutter.components.googlepay.advanced

import ComponentCommunicationModel
import ComponentFlutterInterface
import PaymentResultDTO
import PaymentResultModelDTO
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.googlepay.BaseGooglePayComponent
import com.adyen.checkout.flutter.components.googlepay.GooglePayComponentManager
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_ADVANCED_REQUEST_CODE
import com.adyen.checkout.googlepay.GooglePayComponent
import com.adyen.checkout.googlepay.GooglePayConfiguration
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import java.util.UUID

class GooglePayAdvancedComponent(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val googlePayConfiguration: GooglePayConfiguration,
    override val componentId: String,
) : BaseGooglePayComponent(activity) {
    init {
        addResultListener()
        addActionListener()
        addErrorListener()
    }

    private var resultListenerJob: Job? = null
    private var actionListenerJob: Job? = null
    private var errorListenerJob: Job? = null

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
                key = UUID.randomUUID().toString()
            )
    }

    override fun startGooglePayScreen() {
        googlePayComponent?.startGooglePayScreen(activity, GOOGLE_PAY_ADVANCED_REQUEST_CODE)
    }

    override fun dispose() {
        resultListenerJob?.cancel()
        actionListenerJob?.cancel()
        errorListenerJob?.cancel()
        clear()
    }

    private fun addResultListener() {
        resultListenerJob =
            activity.lifecycleScope.launch {
                GooglePayComponentManager.resultFlow.collect { resultCode ->
                    if (resultCode == null) {
                        return@collect
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
            }
    }

    private fun addActionListener() {
        actionListenerJob =
            activity.lifecycleScope.launch {
                GooglePayComponentManager.actionFlow.collect { action ->
                    if (action == null) {
                        return@collect
                    }

                    action.let {
                        googlePayComponent?.apply {
                            this.handleAction(action = Action.SERIALIZER.deserialize(action), activity = activity)
                            ComponentLoadingBottomSheet.show(activity.supportFragmentManager, this)
                        }
                    }
                }
            }
    }

    private fun addErrorListener() {
        errorListenerJob =
            activity.lifecycleScope.launch {
                GooglePayComponentManager.errorFlow.collect { error ->
                    if (error == null) {
                        return@collect
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
                }
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
