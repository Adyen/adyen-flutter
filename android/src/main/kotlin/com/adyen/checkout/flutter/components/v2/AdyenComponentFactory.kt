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
import com.adyen.checkout.flutter.components.v2.BaseComponent.Companion.PAYMENT_METHOD_KEY
import com.adyen.checkout.flutter.generated.ActionResultDTO
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.CheckoutResultDTO
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.ErrorDTO
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
    }

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<*, *>? ?: emptyMap<Any, Any>()
        return if (viewTypeId == ADYEN_COMPONENT_SESSION) {
            AdyenComponent(
                checkoutContext = checkoutHolder.checkoutContext!!,
                checkoutCallbacks = createSessionCheckoutCallbacks("componentId"),
                paymentMethod = createPaymentMethod(creationParams),
                activity = activity,
                creationParams = creationParams,
                onDispose = onDispose,
                platformEventHandler = platformEventHandler,
            )
        } else {
            AdyenComponent(
                checkoutContext = checkoutHolder.checkoutContext!!,
                checkoutCallbacks = createAdvancedCheckoutCallbacks("componentId"),
                paymentMethod = createPaymentMethod(creationParams),
                activity = activity,
                creationParams = creationParams,
                onDispose = onDispose,
                platformEventHandler = platformEventHandler,
            )
        }
    }

    fun createSessionCheckoutCallbacks(componentId: String): CheckoutCallbacks = CheckoutCallbacks(
        onError = { error ->
            println("ON ERROR INVOKED: ${error.message}")
            adyenFlutterInterface.onError(ErrorDTO(
                errorMessage = error.message,
                reason = error.message)
            ) {}
        },
        onFinished = { it: PaymentResult ->
            println("ON FINISHED INVOKED: ${it.resultCode}")
            adyenFlutterInterface.onFinished(
                PaymentResultDTO(
                    type = PaymentResultEnum.FINISHED,
                    result = PaymentResultModelDTO(resultCode = it.resultCode)
                )
            ) {}
        }
    )

    fun createAdvancedCheckoutCallbacks(componentId: String): CheckoutCallbacks = CheckoutCallbacks(
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
                    result.onSuccess { response: CheckoutResultDTO ->
                        println("ON SUBMIT RESPONSE FROM FLUTTER: $response")
                        val onSubmitResult: CheckoutResult = mapPaymentResult(response)
                        continuation.resume(onSubmitResult)
                    }.onFailure { error ->
                        println("Flutter onSubmit error: $error")
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
                    result.onSuccess { response: CheckoutResultDTO ->
                        println("Flutter onAdditionalDetails response: $response")
                        val onAdditionalDetailsResult: CheckoutResult = mapPaymentResult(response)
                        continuation.resume(onAdditionalDetailsResult)
                    }.onFailure { error ->
                        println("Flutter onAdditionalDetails error: $error")
                        continuation.resumeWithException(Exception("Additional details failed: ${error.message}"))
                    }
                }
            }
        },
        onError = { error ->
            println("ON ERROR INVOKED: ${error.message}")
            adyenFlutterInterface.onError(ErrorDTO(
                errorMessage = error.message,
                reason = error.message)
            ) {}
        },
        onFinished = { it: PaymentResult ->
            println("ON FINISHED INVOKED: ${it.resultCode}")
            adyenFlutterInterface.onFinished(
                PaymentResultDTO(
                    type = PaymentResultEnum.FINISHED,
                    result = PaymentResultModelDTO(resultCode = it.resultCode)
                )
            ) {}
        }
    )

    fun createPaymentMethod(creationParams: Map<*, *>): PaymentMethod {
        val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
        return PaymentMethod.SERIALIZER.deserialize(JSONObject(paymentMethodString))
    }

    private fun mapPaymentResult(response: CheckoutResultDTO): CheckoutResult = when (response) {
        is ErrorResultDTO -> CheckoutResult.Error(response.errorMessage)
        is FinishedResultDTO -> CheckoutResult.Finished(response.resultCode)
        is ActionResultDTO -> CheckoutResult.Action(
            Action.SERIALIZER.deserialize(JSONObject(response.actionResponse))
        )
    }

}
