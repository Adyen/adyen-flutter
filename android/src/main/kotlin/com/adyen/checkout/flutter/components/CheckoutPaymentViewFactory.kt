package com.adyen.checkout.flutter.components

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.card.BinLookupData
import com.adyen.checkout.card.OnBinChangeCallback
import com.adyen.checkout.card.OnBinLookupCallback
import com.adyen.checkout.card.card
import com.adyen.checkout.core.action.data.Action
import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.AdditionalDetailsResult
import com.adyen.checkout.core.components.AdvancedCheckoutCallbacks
import com.adyen.checkout.core.components.AdvancedCheckoutResult
import com.adyen.checkout.core.components.BeforeSubmitResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.CheckoutTarget
import com.adyen.checkout.core.components.SessionCheckoutCallbacks
import com.adyen.checkout.core.components.SessionCheckoutResult
import com.adyen.checkout.core.components.SubmitResult
import com.adyen.checkout.core.components.data.Address
import com.adyen.checkout.core.components.data.BeforeSubmitData
import com.adyen.checkout.core.components.data.PaymentComponentData
import com.adyen.checkout.core.components.data.ShopperName
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethod
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethodResponse
import com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod
import com.adyen.checkout.flutter.generated.ActionComponentDataDTO
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.AddressDTO
import com.adyen.checkout.flutter.generated.BeforeSubmitDataDTO
import com.adyen.checkout.flutter.generated.BeforeSubmitResultDTO
import com.adyen.checkout.flutter.generated.BinLookupBrandDTO
import com.adyen.checkout.flutter.generated.BinLookupDataDTO
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutEventTypeDTO
import com.adyen.checkout.flutter.generated.ComponentHostApi
import com.adyen.checkout.flutter.generated.PaymentComponentDataDTO
import com.adyen.checkout.flutter.generated.SubmitResultDTO
import com.adyen.checkout.flutter.generated.SubmitResultTypeDTO
import com.adyen.checkout.flutter.generated.ShopperNameDTO
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.Constants
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume

internal class CheckoutPaymentViewFactory(
    private val activity: FragmentActivity,
    private val checkoutHolder: CheckoutHolder,
    private val callbacksApi: CheckoutCallbacksFlutterApi,
    private val eventHandler: ComponentPlatformEventHandler,
) : PlatformViewFactory(ComponentHostApi.codec) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView {
        val creationParams = args as? Map<*, *> ?: emptyMap<Any, Any>()
        val checkoutId = creationParams[Constants.CHECKOUT_ID_KEY] as? String
            ?: throw IllegalArgumentException("checkoutId is required.")
        val componentId = creationParams[Constants.COMPONENT_ID_KEY] as? String
            ?: throw IllegalArgumentException("componentId is required.")
        val paymentMethodJson = creationParams[Constants.PAYMENT_METHOD_KEY] as? String
            ?: throw IllegalArgumentException("paymentMethod is required.")
        val isStoredPaymentMethod = creationParams[Constants.IS_STORED_PAYMENT_METHOD_KEY] as? Boolean ?: false
        val checkoutContext = checkoutHolder.get(checkoutId)
            ?: throw AdyenPigeonError("CheckoutNotFound", "Checkout is no longer active.")
        val paymentMethod = deserializePaymentMethod(paymentMethodJson, isStoredPaymentMethod)
        val callbacks = createCallbacks(checkoutId, componentId, checkoutContext)

        return CheckoutPaymentView(
            activity = activity,
            context = context,
            checkoutId = checkoutId,
            componentId = componentId,
            paymentMethod = paymentMethod,
            checkoutContext = checkoutContext,
            callbacks = callbacks,
            eventHandler = eventHandler,
        )
    }

    private fun deserializePaymentMethod(
        json: String,
        isStoredPaymentMethod: Boolean,
    ): PaymentMethodResponse {
        val jsonObject = JSONObject(json)
        return if (isStoredPaymentMethod) {
            StoredPaymentMethod.SERIALIZER.deserialize(jsonObject)
        } else {
            PaymentMethod.SERIALIZER.deserialize(jsonObject)
        }
    }

    private fun createCallbacks(
        checkoutId: String,
        componentId: String,
        checkoutContext: CheckoutContext,
    ): CheckoutCallbacks {
        val terminalState = TerminalState(checkoutId, componentId, eventHandler)
        return when (checkoutContext) {
            is CheckoutContext.Sessions -> SessionCheckoutCallbacks(
                onComplete = { result -> terminalState.complete(result) },
                onFailure = { error -> terminalState.failure(error.code, error.message) },
                onBeforeSubmit = { data -> requestBeforeSubmit(checkoutId, data, terminalState) },
                additionalCallbacksBlock = { registerCardCallbacks(checkoutId, componentId) },
            )

            is CheckoutContext.Advanced -> AdvancedCheckoutCallbacks(
                onSubmit = { data -> requestSubmit(checkoutId, componentId, data) },
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
            onBinChange = OnBinChangeCallback { binValue ->
                eventHandler.send(
                    CheckoutEventDTO(
                        type = CheckoutEventTypeDTO.BIN_VALUE,
                        checkoutId = checkoutId,
                        componentId = componentId,
                        binValue = binValue,
                    ),
                )
            },
            onBinLookup = OnBinLookupCallback { data ->
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
    ): BeforeSubmitResult = suspendCancellableCoroutine { continuation ->
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
        continuation.invokeOnCancellation { }
    }

    private suspend fun requestSubmit(
        checkoutId: String,
        componentId: String,
        data: PaymentComponentData<*>,
    ): SubmitResult = suspendCancellableCoroutine { continuation ->
        CheckoutComponentRegistry.setActive(checkoutId, componentId)
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
        continuation.invokeOnCancellation { }
    }

    private suspend fun requestAdditionalDetails(
        checkoutId: String,
        data: ActionComponentData,
        terminalState: TerminalState,
    ): AdditionalDetailsResult = suspendCancellableCoroutine { continuation ->
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
        continuation.invokeOnCancellation { }
    }

    private fun SubmitResultDTO.toNativeSubmitResult(): SubmitResult = when (type) {
        SubmitResultTypeDTO.COMPLETION -> {
            val code = resultCode ?: throw AdyenPigeonError(
                "InvalidSubmitResult",
                "Submit completion did not contain a result code.",
            )
            SubmitResult.Completion(code)
        }

        SubmitResultTypeDTO.ACTION -> {
            val actionJson = actionJson ?: throw AdyenPigeonError(
                "InvalidSubmitResult",
                "Submit action did not contain action data.",
            )
            SubmitResult.Action(Action.SERIALIZER.deserialize(JSONObject(actionJson)))
        }

        SubmitResultTypeDTO.RETRY -> SubmitResult.Retry(errorMessage)
    }

    private fun com.adyen.checkout.flutter.generated.AdditionalDetailsResultDTO.toNativeAdditionalDetailsResult(): AdditionalDetailsResult =
        AdditionalDetailsResult.Completion(resultCode)

    private fun BeforeSubmitResultDTO.toNativeBeforeSubmitResult(): BeforeSubmitResult =
        if (isAborted) {
            BeforeSubmitResult.Abort()
        } else {
            BeforeSubmitResult.Proceed(
                data = data?.toNativeBeforeSubmitData() ?: BeforeSubmitData(),
                sessionData = sessionData,
            )
        }

    private fun BeforeSubmitData.toDTO(): BeforeSubmitDataDTO = BeforeSubmitDataDTO(
        billingAddress = billingAddress?.toDTO(),
        deliveryAddress = deliveryAddress?.toDTO(),
        shopperName = shopperName?.toDTO(),
        shopperEmail = shopperEmail,
    )

    private fun BeforeSubmitDataDTO.toNativeBeforeSubmitData(): BeforeSubmitData = BeforeSubmitData(
        billingAddress = billingAddress?.toNativeAddress(),
        deliveryAddress = deliveryAddress?.toNativeAddress(),
        shopperName = shopperName?.toNativeShopperName(),
        shopperEmail = shopperEmail,
    )

    private fun Address.toDTO(): AddressDTO = AddressDTO(
        city = city,
        country = country,
        houseNumberOrName = houseNumberOrName,
        postalCode = postalCode,
        stateOrProvince = stateOrProvince,
        street = street,
    )

    private fun AddressDTO.toNativeAddress(): Address = Address(
        city = city,
        country = country,
        houseNumberOrName = houseNumberOrName,
        postalCode = postalCode,
        stateOrProvince = stateOrProvince,
        street = street,
    )

    private fun ShopperName.toDTO(): ShopperNameDTO = ShopperNameDTO(
        firstName = firstName,
        lastName = lastName,
        infix = infix,
        gender = gender,
    )

    private fun ShopperNameDTO.toNativeShopperName(): ShopperName = ShopperName(
        firstName = firstName,
        lastName = lastName,
        infix = infix,
        gender = gender,
    )

    private fun BinLookupData.toDTO(): BinLookupDataDTO = BinLookupDataDTO(
        issuingCountryCode = issuingCountryCode,
        brands = brands.map { brand ->
            BinLookupBrandDTO(
                brand = brand.brand,
                supported = brand.supported,
                paymentMethodVariant = brand.paymentMethodVariant,
            )
        },
    )

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
                    sessionData = result.sessionData,
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

        fun failure(code: String, message: String?) {
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
