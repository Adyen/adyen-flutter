package com.adyen.checkout.flutter.components.v2

import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.core.action.data.Action
import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.components.AdvancedCheckoutResult
import com.adyen.checkout.core.components.BeforeSubmitResult
import com.adyen.checkout.core.components.CheckoutCallbacks
import com.adyen.checkout.core.components.SessionCheckoutResult
import com.adyen.checkout.core.components.SubmitResult
import com.adyen.checkout.core.components.AdditionalDetailsResult
import com.adyen.checkout.core.components.SessionCheckoutCallbacks
import com.adyen.checkout.core.components.AdvancedCheckoutCallbacks
import com.adyen.checkout.core.components.data.Address
import com.adyen.checkout.core.components.data.BeforeSubmitData
import com.adyen.checkout.core.components.data.PaymentComponentData
import com.adyen.checkout.core.components.data.ShopperName
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethod
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethodResponse
import com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ActionResultDTO
import com.adyen.checkout.flutter.generated.AddressDTO
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.BeforeSubmitDataDTO
import com.adyen.checkout.flutter.generated.BeforeSubmitResultDTO
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
import com.adyen.checkout.flutter.generated.SessionCheckoutFlutterInterface
import com.adyen.checkout.flutter.generated.ShopperNameDTO
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToPaymentResultModelDTO
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import kotlin.collections.get
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.onSuccess

internal class AdyenComponentFactory(
    private val activity: FragmentActivity,
    private val adyenFlutterInterface: AdyenFlutterInterface,
    private val sessionCheckoutFlutterInterface: SessionCheckoutFlutterInterface,
    private val platformEventHandler: ComponentPlatformEventHandler,
    private val viewTypeId: String,
    private val onDispose: (String) -> Unit,
    private val checkoutHolder: CheckoutHolder,
) : PlatformViewFactory(ComponentFlutterInterface.codec) {
    companion object {
        const val ADYEN_COMPONENT_ADVANCED = "AdyenAdvancedComponent"
        const val ADYEN_COMPONENT_SESSION = "AdyenSessionComponent"
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
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
            activity = activity,
            checkoutContext = checkoutHolder.checkoutContext!!,
            checkoutCallbacks = createCheckoutCallbacks(componentId),
            paymentMethod = createPaymentMethod(creationParams),
            context = context,
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

    fun createSessionCheckoutCallbacks(componentId: String): SessionCheckoutCallbacks =
        SessionCheckoutCallbacks(
            onFailure = { checkoutError -> sendError(componentId, checkoutError.message) },
            onComplete = { sessionCheckoutResult -> sendFinished(componentId, sessionCheckoutResult) },
            onBeforeSubmit = { data -> onBeforeSubmit(data) },
        )

    fun createAdvancedCheckoutCallbacks(componentId: String): AdvancedCheckoutCallbacks =
        AdvancedCheckoutCallbacks(
            onSubmit = { state ->
                println("ON SUBMIT ON ANDROID INVOKED")
                val model =
                    PlatformCommunicationDTO(
                        type = ComponentCommunicationType.ON_SUBMIT,
                        componentId = componentId,
                        dataJson = PaymentComponentData.SERIALIZER.serialize(state).toString()
                    )

                suspendCancellableCoroutine<SubmitResult> { continuation ->
                    adyenFlutterInterface.onSubmit(model) { result: Result<CheckoutResultDTO> ->
                        result
                            .onSuccess { response: CheckoutResultDTO ->
                                println("ON SUBMIT RESPONSE FROM FLUTTER: $response")
                                val onSubmitResult: SubmitResult = mapToSubmitResult(response)
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

                suspendCancellableCoroutine<AdditionalDetailsResult> { continuation ->
                    adyenFlutterInterface.onAdditionalDetails(model) { result: Result<CheckoutResultDTO> ->
                        result
                            .onSuccess { response: CheckoutResultDTO ->
                                println("Flutter onAdditionalDetails response: $response")
                                val onAdditionalDetailsResult: AdditionalDetailsResult = mapToAdditionalDetailsResult(response)
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
            onFailure = { error -> sendError(componentId, error.message) },
            onComplete = { advancedCheckoutResult -> sendFinished(componentId, advancedCheckoutResult) }
        )

    fun createPaymentMethod(creationParams: Map<*, *>): PaymentMethodResponse {
        val paymentMethodString = creationParams[PAYMENT_METHOD_KEY] as String? ?: ""
        val isStoredPaymentMethod = creationParams[IS_STORED_PAYMENT_METHOD_KEY] as Boolean? ?: false
        val jsonObject = JSONObject(paymentMethodString)
        return if (isStoredPaymentMethod) {
            StoredPaymentMethod.SERIALIZER.deserialize(jsonObject)
        } else {
            PaymentMethod.SERIALIZER.deserialize(jsonObject)
        }
    }

    private fun mapToSubmitResult(response: CheckoutResultDTO): SubmitResult =
        when (response) {
            is ErrorResultDTO -> SubmitResult.Completion("Error")
            is FinishedResultDTO -> SubmitResult.Completion(response.resultCode)
            is ActionResultDTO ->
                SubmitResult.Action(
                    Action.SERIALIZER.deserialize(JSONObject(response.actionResponse))
                )
        }

    private fun mapToAdditionalDetailsResult(response: CheckoutResultDTO): AdditionalDetailsResult =
        when (response) {
            is ErrorResultDTO -> AdditionalDetailsResult.Completion("Error")
            is FinishedResultDTO -> AdditionalDetailsResult.Completion(response.resultCode)
            is ActionResultDTO -> AdditionalDetailsResult.Completion("Error")
        }

    private suspend fun onBeforeSubmit(data: BeforeSubmitData): BeforeSubmitResult =
        suspendCancellableCoroutine { continuation ->
            sessionCheckoutFlutterInterface.onBeforeSubmit(data.toDTO()) { result: Result<BeforeSubmitResultDTO> ->
                result
                    .onSuccess { response: BeforeSubmitResultDTO -> continuation.resume(response.mapToBeforeSubmitResult()) }
                    .onFailure { error -> continuation.resumeWithException(Exception("onBeforeSubmit failed: ${error.message}")) }
            }
        }

    private fun BeforeSubmitData.toDTO(): BeforeSubmitDataDTO =
        BeforeSubmitDataDTO(
            billingAddress = billingAddress?.toDTO(),
            deliveryAddress = deliveryAddress?.toDTO(),
            shopperName = shopperName?.toDTO(),
            shopperEmail = shopperEmail
        )

    private fun Address.toDTO(): AddressDTO =
        AddressDTO(
            city = city,
            country = country,
            houseNumberOrName = houseNumberOrName,
            postalCode = postalCode,
            stateOrProvince = stateOrProvince,
            street = street
        )

    private fun ShopperName.toDTO(): ShopperNameDTO =
        ShopperNameDTO(
            firstName = firstName,
            lastName = lastName,
            infix = infix,
            gender = gender
        )

    private fun BeforeSubmitResultDTO.mapToBeforeSubmitResult(): BeforeSubmitResult =
        if (isAborted) {
            BeforeSubmitResult.Abort()
        } else {
            BeforeSubmitResult.Proceed(
                data = data?.fromDTO() ?: BeforeSubmitData(),
                sessionData = sessionData
            )
        }

    private fun BeforeSubmitDataDTO.fromDTO(): BeforeSubmitData =
        BeforeSubmitData(
            billingAddress = billingAddress?.fromDTO(),
            deliveryAddress = deliveryAddress?.fromDTO(),
            shopperName = shopperName?.fromDTO(),
            shopperEmail = shopperEmail
        )

    private fun AddressDTO.fromDTO(): Address =
        Address(
            city = city,
            country = country,
            houseNumberOrName = houseNumberOrName,
            postalCode = postalCode,
            stateOrProvince = stateOrProvince,
            street = street
        )

    private fun ShopperNameDTO.fromDTO(): ShopperName =
        ShopperName(
            firstName = firstName,
            lastName = lastName,
            infix = infix,
            gender = gender
        )

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

    private fun sendFinished(componentId: String, sessionCheckoutResult: SessionCheckoutResult) {
        println("ON FINISHED INVOKED: ${sessionCheckoutResult.resultCode}")
        platformEventHandler.eventSink?.success(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = PaymentResultDTO(
                    type = PaymentResultEnum.FINISHED,
                    result = sessionCheckoutResult.mapToPaymentResultModelDTO()
                ),
            )
        )
    }

    private fun sendFinished(componentId: String, advancedCheckoutResult: AdvancedCheckoutResult) {
        println("ON FINISHED INVOKED: ${advancedCheckoutResult.resultCode}")
        platformEventHandler.eventSink?.success(
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = PaymentResultDTO(
                    type = PaymentResultEnum.FINISHED,
                    result = advancedCheckoutResult.mapToPaymentResultModelDTO()
                ),
            )
        )
    }
}
