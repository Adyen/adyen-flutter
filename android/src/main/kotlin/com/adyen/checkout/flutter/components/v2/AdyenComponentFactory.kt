package com.adyen.checkout.flutter.components.v2

import android.content.Context
import androidx.activity.ComponentActivity
import com.adyen.checkout.core.action.data.Action
import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.common.PaymentResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutResult
import com.adyen.checkout.core.components.data.PaymentComponentData
import com.adyen.checkout.core.components.data.model.PaymentMethod
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ActionResultDTO
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.CheckoutResultDTO
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.ErrorResultDTO
import com.adyen.checkout.flutter.generated.FinishedResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum
import com.adyen.checkout.flutter.generated.PaymentResultModelDTO
import com.adyen.checkout.flutter.generated.PlatformCommunicationDTO
import com.adyen.checkout.flutter.session.CheckoutHolder
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import kotlin.collections.get
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

internal class AdyenComponentFactory(
    private val adyenFlutterInterface: AdyenFlutterInterface,
    private val platformEventHandler: ComponentPlatformEventHandler,
    private val activity: ComponentActivity,
    private val viewTypeId: String,
    private val onDispose: (String) -> Unit,
    private val checkoutHolder: CheckoutHolder,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    companion object {
        const val ADYEN_COMPONENT_ADVANCED = "AdyenAdvancedComponent"
        const val ADYEN_COMPONENT_SESSION = "AdyenSessionComponent"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val COMPONENT_ID_KEY = "componentId"
    }

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""
        return AdyenComponent(
            checkoutContext = checkoutHolder.checkoutContext!!,
            checkoutCallbacks = createCheckoutCallbacks(componentId),
            paymentMethod = createPaymentMethod(creationParams),
            activity = activity,
            componentId = componentId,
            onDispose = onDispose,
            platformEventHandler = platformEventHandler,
        )
    }

    private fun createCheckoutCallbacks(componentId: String): CheckoutCallbacks =
        if (viewTypeId == ADYEN_COMPONENT_SESSION) {
            createSessionCheckoutCallbacks(componentId)
        } else {
            createAdvancedCheckoutCallbacks(componentId)
        }

    fun createSessionCheckoutCallbacks(componentId: String): CheckoutCallbacks =
        CheckoutCallbacks(
            onError = { checkoutError -> sendError(componentId, checkoutError.message) },
            onFinished = { paymentResult -> sendFinished(componentId, paymentResult.resultCode) }
        )

    fun createAdvancedCheckoutCallbacks(componentId: String): CheckoutCallbacks =
        CheckoutCallbacks(
            onSubmit = { state ->
                println("ON SUBMIT ON ANDROID INVOKED")
                val model =
                    PlatformCommunicationDTO(
                        type = ComponentCommunicationType.ON_SUBMIT,
                        componentId = componentId,
                        dataJson = PaymentComponentData.SERIALIZER.serialize(state.data).toString()
                    )

                suspendCancellableCoroutine<CheckoutResult> { continuation ->
                    adyenFlutterInterface.onSubmit(model) { result: Result<CheckoutResultDTO> ->
                        result
                            .onSuccess { response: CheckoutResultDTO ->
                                println("ON SUBMIT RESPONSE FROM FLUTTER: $response")
                                val onSubmitResult: CheckoutResult = mapPaymentResult(response)
                                continuation.resume(onSubmitResult)
                            }.onFailure { error ->
                                println("Flutter onSubmit error: $error")
                                sendError(componentId, error.message)
                                continuation.resumeWithException(Exception("Submit failed: ${error.message}"))
                            }
                    }
                }
            },
            onAdditionalDetails = { state ->
                println("ON ADDITIONAL DETAILS INVOKED")
                val model =
                    PlatformCommunicationDTO(
                        type = ComponentCommunicationType.ADDITIONAL_DETAILS,
                        componentId = componentId,
                        dataJson = ActionComponentData.SERIALIZER.serialize(state).toString()
                    )

                suspendCancellableCoroutine<CheckoutResult> { continuation ->
                    adyenFlutterInterface.onAdditionalDetails(model) { result: Result<CheckoutResultDTO> ->
                        result
                            .onSuccess { response: CheckoutResultDTO ->
                                println("Flutter onAdditionalDetails response: $response")
                                val onAdditionalDetailsResult: CheckoutResult = mapPaymentResult(response)
                                continuation.resume(onAdditionalDetailsResult)
                            }.onFailure { error ->
                                println("Flutter onAdditionalDetails error: $error")
                                sendError(componentId, error.message)
                                continuation.resumeWithException(
                                    Exception("Additional details failed: ${error.message}")
                                )
                            }
                    }
                }
            },
            onError = { error -> sendError(componentId, error.message) },
            onFinished = { it: PaymentResult -> sendFinished(componentId, it.resultCode) }
        )

    fun createPaymentMethod(creationParams: Map<*, *>): PaymentMethod {
        val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
        return PaymentMethod.SERIALIZER.deserialize(JSONObject(paymentMethodString))
    }

    private fun mapPaymentResult(response: CheckoutResultDTO): CheckoutResult =
        when (response) {
            is ErrorResultDTO -> CheckoutResult.Error(response.errorMessage)
            is FinishedResultDTO -> CheckoutResult.Finished(response.resultCode)
            is ActionResultDTO ->
                CheckoutResult.Action(
                    Action.SERIALIZER.deserialize(JSONObject(response.actionResponse))
                )
        }

    private fun sendError(componentId: String, errorMessage: String?) {
        println("ON ERROR INVOKED: $errorMessage")
        platformEventHandler.eventSink?.success(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = PaymentResultDTO(
                    type = PaymentResultEnum.ERROR,
                    reason = errorMessage
                ),
            )
        )
    }

    private fun sendFinished(componentId: String, resultCode: String) {
        println("ON FINISHED INVOKED: $resultCode")
        platformEventHandler.eventSink?.success(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = PaymentResultDTO(
                    type = PaymentResultEnum.FINISHED,
                    result = PaymentResultModelDTO(resultCode = resultCode)
                ),
            )
        )
    }
}
