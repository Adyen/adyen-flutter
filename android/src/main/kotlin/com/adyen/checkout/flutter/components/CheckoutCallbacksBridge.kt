package com.adyen.checkout.flutter.components

import com.adyen.checkout.card.OnBinChangeCallback
import com.adyen.checkout.card.OnBinLookupCallback
import com.adyen.checkout.card.card
import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.action.data.ActionData
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.AdditionalDetailsResult
import com.adyen.checkout.core.components.AdvancedCheckoutCallbacks
import com.adyen.checkout.core.components.AdvancedCheckoutResult
import com.adyen.checkout.core.components.BeforeSubmitResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.SessionCheckoutCallbacks
import com.adyen.checkout.core.components.SessionCheckoutResult
import com.adyen.checkout.core.components.SubmitResult
import com.adyen.checkout.core.components.data.BeforeSubmitData
import com.adyen.checkout.core.components.data.PaymentComponentData
import com.adyen.checkout.flutter.generated.ActionComponentDataDTO
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutEventTypeDTO
import com.adyen.checkout.flutter.generated.PaymentComponentDataDTO
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toDTO
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeAdditionalDetailsResult
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeBeforeSubmitResult
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeSubmitResult
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume

internal class CheckoutCallbacksBridge(
    private val callbacksApi: CheckoutCallbacksFlutterApi,
    private val eventHandler: ComponentPlatformEventHandler,
    private val registry: CheckoutComponentRegistry,
) {
    fun createCallbacks(
        checkoutId: String,
        componentId: String,
        checkoutContext: CheckoutContext,
        onAction: (ActionData) -> Unit,
    ): CheckoutCallbacks {
        val terminalState = TerminalState(checkoutId, componentId, eventHandler)
        return when (checkoutContext) {
            is CheckoutContext.Sessions ->
                SessionCheckoutCallbacks(
                    onAction = onAction,
                    onComplete = { result -> terminalState.complete(result) },
                    onFailure = { error -> terminalState.failure(error.code, error.message) },
                    onBeforeSubmit = { data -> requestBeforeSubmit(checkoutId, data, terminalState) },
                    additionalCallbacksBlock = { registerCardCallbacks(checkoutId, componentId) },
                )

            is CheckoutContext.Advanced ->
                AdvancedCheckoutCallbacks(
                    onSubmit = { data -> requestSubmit(checkoutId, componentId, data) },
                    onAction = onAction,
                    onAdditionalDetails = { data ->
                        requestAdditionalDetails(checkoutId, data, terminalState)
                    },
                    onFailure = { error -> terminalState.failure(error.code, error.message) },
                    onComplete = { result -> terminalState.complete(result) },
                    additionalCallbacksBlock = { registerCardCallbacks(checkoutId, componentId) },
                )

            is CheckoutContext.ActionOnly -> throw IllegalArgumentException(
                "Action-only checkouts do not create payment components.",
            )
        }
    }

    private fun CheckoutCallbacks.registerCardCallbacks(
        checkoutId: String,
        componentId: String,
    ) {
        card(
            onBinChange =
                OnBinChangeCallback { binValue ->
                    eventHandler.send(
                        CheckoutEventDTO(
                            type = CheckoutEventTypeDTO.BIN_VALUE,
                            checkoutId = checkoutId,
                            componentId = componentId,
                            binValue = binValue,
                        ),
                    )
                },
            onBinLookup =
                OnBinLookupCallback { data ->
                    eventHandler.send(
                        CheckoutEventDTO(
                            type = CheckoutEventTypeDTO.BIN_LOOKUP,
                            checkoutId = checkoutId,
                            componentId = componentId,
                            binLookupData = listOf(data.toDTO()),
                        ),
                    )
                },
        )
    }

    private suspend fun requestBeforeSubmit(
        checkoutId: String,
        data: BeforeSubmitData,
        terminalState: TerminalState,
    ): BeforeSubmitResult =
        suspendCancellableCoroutine { continuation ->
            callbacksApi.onBeforeSubmit(
                checkoutId,
                data.toDTO(),
            ) { result ->
                if (!continuation.isActive) return@onBeforeSubmit
                result.fold(
                    onSuccess = { response -> continuation.resume(response.toNativeBeforeSubmitResult()) },
                    onFailure = { error ->
                        terminalState.failure("CallbackFailure", error.message)
                        continuation.resume(BeforeSubmitResult.Abort())
                    },
                )
            }
        }

    private suspend fun requestSubmit(
        checkoutId: String,
        componentId: String,
        data: PaymentComponentData<*>,
    ): SubmitResult =
        suspendCancellableCoroutine { continuation ->
            registry.setActive(checkoutId, componentId)
            val dataJson = PaymentComponentData.SERIALIZER.serialize(data).toString()
            callbacksApi.onSubmit(
                checkoutId,
                PaymentComponentDataDTO(dataJson = dataJson),
            ) { result ->
                if (!continuation.isActive) return@onSubmit
                result.fold(
                    onSuccess = { response -> continuation.resume(response.toNativeSubmitResult()) },
                    onFailure = { error ->
                        continuation.resume(SubmitResult.Retry(error.message))
                    },
                )
            }
        }

    private suspend fun requestAdditionalDetails(
        checkoutId: String,
        data: ActionComponentData,
        terminalState: TerminalState,
    ): AdditionalDetailsResult =
        suspendCancellableCoroutine { continuation ->
            val dataJson = ActionComponentData.SERIALIZER.serialize(data).toString()
            callbacksApi.onAdditionalDetails(
                checkoutId,
                ActionComponentDataDTO(dataJson = dataJson),
            ) { result ->
                if (!continuation.isActive) return@onAdditionalDetails
                result.fold(
                    onSuccess = { response -> continuation.resume(response.toNativeAdditionalDetailsResult()) },
                    onFailure = { error ->
                        terminalState.failure("CallbackFailure", error.message)
                        continuation.resume(AdditionalDetailsResult.Completion("Error"))
                    },
                )
            }
        }

    private class TerminalState(
        private val checkoutId: String,
        private val componentId: String,
        private val eventHandler: ComponentPlatformEventHandler,
    ) {
        private val terminal = AtomicBoolean(false)

        fun complete(result: SessionCheckoutResult) {
            if (!terminal.compareAndSet(false, true)) return
            eventHandler.send(
                CheckoutEventDTO(
                    type = CheckoutEventTypeDTO.COMPLETE,
                    checkoutId = checkoutId,
                    componentId = componentId,
                    resultCode = result.resultCode.value,
                    sessionId = result.sessionId,
                    sessionResult = result.sessionResult,
                ),
            )
        }

        fun complete(result: AdvancedCheckoutResult) {
            if (!terminal.compareAndSet(false, true)) return
            eventHandler.send(
                CheckoutEventDTO(
                    type = CheckoutEventTypeDTO.COMPLETE,
                    checkoutId = checkoutId,
                    componentId = componentId,
                    resultCode = result.resultCode.value,
                ),
            )
        }

        fun failure(
            code: String,
            message: String?,
        ) {
            if (!terminal.compareAndSet(false, true)) return
            eventHandler.send(
                CheckoutEventDTO(
                    type = CheckoutEventTypeDTO.FAILURE,
                    checkoutId = checkoutId,
                    componentId = componentId,
                    errorCode = code,
                    errorMessage = message,
                ),
            )
        }
    }
}
