package com.adyen.checkout.flutter.components.v2

import android.content.Context
import com.adyen.checkout.core.action.data.Action
import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.common.PaymentResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutResult
import com.adyen.checkout.core.components.data.PaymentComponentData
import com.adyen.checkout.core.components.data.model.PaymentMethod
import com.adyen.checkout.flutter.generated.ActionResultDTO
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.CheckoutResultDTO
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.ErrorResultDTO
import com.adyen.checkout.flutter.generated.FinishedResultDTO
import com.adyen.checkout.flutter.generated.PlatformCommunicationDTO
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.PlatformException
import org.json.JSONObject
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

internal class AdyenAdvancedComponent(
    checkoutHolder: CheckoutHolder,
    context: Context,
    creationParams: Map<*, *>,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val adyenFlutterInterface: AdyenFlutterInterface,
    private val onDispose: (String) -> Unit,
) : BaseComponent(
    checkoutHolder,
    context,
    creationParams,
    componentFlutterApi,
    adyenFlutterInterface,
    onDispose,
) {
    init {
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(
            JSONObject(paymentMethodString)
        )
        val checkoutContext = checkoutHolder.checkoutContext as? CheckoutContext.Advanced
            ?: throw PlatformException("Checkout not initialized")

        val checkoutCallbacks = CheckoutCallbacks(
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
            onError = {
                println("ON ERROR INVOKED")
            },
            onFinished = { it: PaymentResult ->
                println("ON FINISHED INVOKED: ${it.sessionResult}")
            }
        )

        dynamicComponentView.addV6Component(
            paymentMethod = paymentMethod,
            checkoutContext = checkoutContext,
            callbacks = checkoutCallbacks
        )
    }

    private fun mapPaymentResult(response: CheckoutResultDTO): CheckoutResult = when (response) {
        is ErrorResultDTO -> CheckoutResult.Error(response.errorMessage)
        is FinishedResultDTO -> CheckoutResult.Finished(response.resultCode)
        is ActionResultDTO -> CheckoutResult.Action(
            Action.SERIALIZER.deserialize(JSONObject(response.actionResponse))
        )
    }
}
