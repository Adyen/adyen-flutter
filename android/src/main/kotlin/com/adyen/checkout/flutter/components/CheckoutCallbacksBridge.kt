package com.adyen.checkout.flutter.components

import com.adyen.checkout.card.OnBinChangeCallback
import com.adyen.checkout.card.OnBinLookupCallback
import com.adyen.checkout.card.card
import com.adyen.checkout.core.action.data.ActionData
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.BeforeSubmitResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.SessionCheckoutCallbacks
import com.adyen.checkout.core.components.SessionCheckoutResult
import com.adyen.checkout.core.components.data.BeforeSubmitData
import com.adyen.checkout.flutter.generated.CardCallbacksDTO
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutEventTypeDTO
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toDTO
import com.adyen.checkout.flutter.utils.CheckoutCallbacksMapper.toNativeBeforeSubmitResult
import com.adyen.checkout.flutter.utils.ErrorCodes
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume

internal class CheckoutCallbacksBridge(
    private val callbacksApi: CheckoutCallbacksFlutterApi,
    private val eventHandler: ComponentPlatformEventHandler,
) {
    fun createCallbacks(
        checkoutId: String,
        componentId: String,
        checkoutContext: CheckoutContext,
        cardCallbacks: CardCallbacksDTO?,
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
                    additionalCallbacksBlock = {
                        registerCardCallbacks(checkoutId, componentId, cardCallbacks)
                    },
                )

            is CheckoutContext.Advanced, is CheckoutContext.ActionOnly -> throw IllegalArgumentException(
                "Only session checkouts create payment components.",
            )
        }
    }

    /**
     * Registers only the card callbacks the Flutter side asked for. When neither flag is set,
     * `card(...)` is not called at all so the native SDK doesn't dispatch BIN events.
     */
    private fun CheckoutCallbacks.registerCardCallbacks(
        checkoutId: String,
        componentId: String,
        cardCallbacks: CardCallbacksDTO?,
    ) {
        val hasOnBinChange = cardCallbacks?.hasOnBinChange == true
        val hasOnBinLookup = cardCallbacks?.hasOnBinLookup == true
        if (!hasOnBinChange && !hasOnBinLookup) return

        val binChangeCallback = if (hasOnBinChange) {
            OnBinChangeCallback { binValue ->
                eventHandler.send(
                    CheckoutEventDTO(
                        type = CheckoutEventTypeDTO.BIN_VALUE,
                        checkoutId = checkoutId,
                        componentId = componentId,
                        binValue = binValue,
                    ),
                )
            }
        } else {
            null
        }
        val binLookupCallback = if (hasOnBinLookup) {
            OnBinLookupCallback { data ->
                eventHandler.send(
                    CheckoutEventDTO(
                        type = CheckoutEventTypeDTO.BIN_LOOKUP,
                        checkoutId = checkoutId,
                        componentId = componentId,
                        binLookupData = listOf(data.toDTO()),
                    ),
                )
            }
        } else {
            null
        }
        card(
            onBinChange = binChangeCallback,
            onBinLookup = binLookupCallback,
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
                        terminalState.failure(ErrorCodes.CALLBACK_FAILURE, error.message)
                        continuation.resume(BeforeSubmitResult.Abort())
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
