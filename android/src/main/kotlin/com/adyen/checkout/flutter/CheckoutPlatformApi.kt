package com.adyen.checkout.flutter

import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.core.action.data.Action
import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.common.AdyenLogLevel
import com.adyen.checkout.core.common.AdyenLogger
import com.adyen.checkout.core.common.CheckoutContext
import com.adyen.checkout.core.components.ActionOnlyCheckoutCallbacks
import com.adyen.checkout.core.components.AdditionalDetailsResult
import com.adyen.checkout.core.components.AdvancedCheckoutResult
import com.adyen.checkout.core.components.Checkout
import com.adyen.checkout.core.components.CheckoutController
import com.adyen.checkout.core.common.CheckoutResultCode
import com.adyen.checkout.core.components.CheckoutAction
import com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethods
import com.adyen.checkout.core.error.CheckoutError
import com.adyen.checkout.cse.CardEncrypter
import com.adyen.checkout.flutter.apiOnly.AdyenCSE
import com.adyen.checkout.flutter.apiOnly.CardValidation
import com.adyen.checkout.flutter.components.CheckoutComponentRegistry
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ActionComponentDataDTO
import com.adyen.checkout.flutter.generated.ActionOnlyFlutterApi
import com.adyen.checkout.flutter.generated.AdyenPigeonError
import com.adyen.checkout.flutter.generated.AdvancedCheckoutResultDTO
import com.adyen.checkout.flutter.generated.CheckoutConfigurationDTO
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutHostApi
import com.adyen.checkout.flutter.generated.CheckoutSetupResultDTO
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.SessionResponseDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.google.android.gms.wallet.WalletConstants
import com.adyen.threeds2.ThreeDS2Service
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import kotlin.coroutines.resume

internal class CheckoutPlatformApi(
    private val activity: FragmentActivity,
    private val checkoutHolder: CheckoutHolder,
    private val callbacksApi: com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi,
    private val actionOnlyApi: ActionOnlyFlutterApi,
    private val eventHandler: ComponentPlatformEventHandler,
) : CheckoutHostApi {
    private var actionController: CheckoutController? = null
    private var actionView: ComposeView? = null

    override fun setupSession(
        sessionResponse: SessionResponseDTO,
        configuration: CheckoutConfigurationDTO,
        callback: (Result<CheckoutSetupResultDTO>) -> Unit,
    ) {
        activity.lifecycleScope.launch {
            try {
                if (checkoutHolder.isActive()) {
                    throw AdyenPigeonError(
                        "CheckoutAlreadyActive",
                        "Another checkout flow is already active.",
                    )
                }
                val nativeConfiguration = configuration.toCheckoutConfiguration()
                val result = Checkout.setup(
                    sessionResponse = sessionResponse.toNativeSessionResponse(),
                    configuration = nativeConfiguration,
                )
                when (result) {
                    is Checkout.Result.Error -> throw result.error.toPigeonError()
                    is Checkout.Result.Success -> {
                        val checkoutId = UUID.randomUUID().toString()
                        checkoutHolder.put(checkoutId, result.checkoutContext)
                        callback(Result.success(result.checkoutContext.toSessionSetupResult(checkoutId)))
                    }
                }
            } catch (error: Throwable) {
                callback(Result.failure(error.toPigeonError()))
            }
        }
    }

    override fun setupAdvanced(
        paymentMethodsJson: String,
        configuration: CheckoutConfigurationDTO,
        callback: (Result<CheckoutSetupResultDTO>) -> Unit,
    ) {
        activity.lifecycleScope.launch {
            try {
                if (checkoutHolder.isActive()) {
                    throw AdyenPigeonError(
                        "CheckoutAlreadyActive",
                        "Another checkout flow is already active.",
                    )
                }
                val paymentMethods = PaymentMethods.SERIALIZER.deserialize(JSONObject(paymentMethodsJson))
                val result = Checkout.setup(
                    paymentMethods = paymentMethods,
                    configuration = configuration.toCheckoutConfiguration(),
                )
                when (result) {
                    is Checkout.Result.Error -> throw result.error.toPigeonError()
                    is Checkout.Result.Success -> {
                        val checkoutId = UUID.randomUUID().toString()
                        checkoutHolder.put(checkoutId, result.checkoutContext)
                        callback(Result.success(setupResult(checkoutId, paymentMethods)))
                    }
                }
            } catch (error: Throwable) {
                callback(Result.failure(error.toPigeonError()))
            }
        }
    }

    override fun disposeCheckout(checkoutId: String) {
        checkoutHolder.remove(checkoutId)
        CheckoutComponentRegistry.clearCheckout(checkoutId)
    }

    override fun handleAction(
        actionId: String,
        actionJson: String,
        configuration: CheckoutConfigurationDTO,
        callback: (Result<AdvancedCheckoutResultDTO>) -> Unit,
    ) {
        if (!checkoutHolder.beginAction(actionId)) {
            callback(
                Result.failure(
                    AdyenPigeonError(
                        "CheckoutAlreadyActive",
                        "Another checkout flow is already active.",
                    ),
                ),
            )
            return
        }

        activity.lifecycleScope.launch {
            try {
                val action = Action.SERIALIZER.deserialize(JSONObject(actionJson))
                val setupResult = Checkout.setup(
                    action = action,
                    configuration = configuration.toCheckoutConfiguration(),
                )
                val context = when (setupResult) {
                    is Checkout.Result.Error -> throw setupResult.error.toPigeonError()
                    is Checkout.Result.Success -> setupResult.checkoutContext
                }
                val result = CompletableDeferred<AdvancedCheckoutResult>()
                val callbacks = ActionOnlyCheckoutCallbacks(
                    onAdditionalDetails = { data ->
                        try {
                            requestActionAdditionalDetails(actionId, data)
                        } catch (error: Throwable) {
                            result.completeExceptionally(error.toPigeonError())
                            AdditionalDetailsResult.Completion(CheckoutResultCode.ERROR.value)
                        }
                    },
                    onFailure = { error ->
                        result.completeExceptionally(error.toPigeonError())
                    },
                    onComplete = { checkoutResult ->
                        result.complete(checkoutResult)
                    },
                )
                val controller = CheckoutController(
                    context = context,
                    callbacks = callbacks,
                    coroutineScope = activity.lifecycleScope,
                )
                actionController = controller
                showAction(controller)
                val checkoutResult = result.await()
                callback(Result.success(AdvancedCheckoutResultDTO(checkoutResult.resultCode.value)))
            } catch (error: Throwable) {
                callback(Result.failure(error.toPigeonError()))
            } finally {
                hideAction()
                actionController = null
                checkoutHolder.endAction(actionId)
            }
        }
    }

    override fun enableConsoleLogging(enabled: Boolean) {
        AdyenLogger.setLogLevel(if (enabled) AdyenLogLevel.VERBOSE else AdyenLogLevel.NONE)
    }

    override fun encryptCard(
        card: UnencryptedCardDTO,
        publicKey: String,
        callback: (Result<EncryptedCardDTO>) -> Unit,
    ) {
        try {
            callback(Result.success(AdyenCSE.encryptCard(card, publicKey)))
        } catch (error: Throwable) {
            callback(Result.failure(error.toPigeonError()))
        }
    }

    override fun encryptBin(
        bin: String,
        publicKey: String,
        callback: (Result<String>) -> Unit,
    ) {
        try {
            callback(Result.success(AdyenCSE.encryptBin(bin, publicKey)))
        } catch (error: Throwable) {
            callback(Result.failure(error.toPigeonError()))
        }
    }

    override fun validateCardNumber(cardNumber: String, enableLuhnCheck: Boolean): Boolean =
        CardValidation.validateCardNumber(cardNumber, enableLuhnCheck)

    override fun validateCardExpiryDate(expiryMonth: String, expiryYear: String): Boolean =
        CardValidation.validateCardExpiryDate(expiryMonth, expiryYear)

    override fun validateCardSecurityCode(securityCode: String, cardBrand: String?): Boolean =
        CardValidation.validateCardSecurityCode(securityCode, cardBrand)

    override fun getThreeDS2SdkVersion(): String = ThreeDS2Service.INSTANCE.sdkVersion

    fun handleReturn(intent: android.content.Intent) {
        actionController?.handleReturn(intent)
    }

    fun teardown() {
        hideAction()
        actionController = null
        checkoutHolder.clear()
    }

    private suspend fun requestActionAdditionalDetails(
        actionId: String,
        data: ActionComponentData,
    ): AdditionalDetailsResult = suspendCancellableCoroutine { continuation ->
        val dataJson = ActionComponentData.SERIALIZER.serialize(data).toString()
        actionOnlyApi.onAdditionalDetails(
            actionId,
            ActionComponentDataDTO(dataJson = dataJson),
        ) { response ->
            if (!continuation.isActive) return@onAdditionalDetails
            response.fold(
                onSuccess = { result ->
                    continuation.resume(AdditionalDetailsResult.Completion(result.resultCode))
                },
                onFailure = { error -> continuation.resumeWith(Result.failure(error)) },
            )
        }
        continuation.invokeOnCancellation { }
    }

    private fun showAction(controller: CheckoutController) {
        val view = ComposeView(activity).apply {
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnDetachedFromWindowOrReleasedFromPool)
            setContent {
                CheckoutAction(controller = controller)
            }
        }
        actionView = view
        activity.addContentView(
            view,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    private fun hideAction() {
        actionView?.let { view ->
            (view.parent as? ViewGroup)?.removeView(view)
        }
        actionView = null
    }

    private fun SessionResponseDTO.toNativeSessionResponse(): com.adyen.checkout.core.sessions.SessionResponse =
        com.adyen.checkout.core.sessions.SessionResponse(id, sessionData)

    private fun CheckoutContext.Sessions.toSessionSetupResult(checkoutId: String): CheckoutSetupResultDTO {
        val methods = checkoutSession.sessionSetupResponse.paymentMethods
        return CheckoutSetupResultDTO(
            checkoutId = checkoutId,
            regularPaymentMethodsJson = serializeMethods(methods?.paymentMethods.orEmpty()),
            storedPaymentMethodsJson = serializeStoredMethods(methods?.storedPaymentMethods.orEmpty()),
        )
    }

    private fun setupResult(
        checkoutId: String,
        methods: PaymentMethods,
    ): CheckoutSetupResultDTO = CheckoutSetupResultDTO(
        checkoutId = checkoutId,
        regularPaymentMethodsJson = serializeMethods(methods.paymentMethods.orEmpty()),
        storedPaymentMethodsJson = serializeStoredMethods(methods.storedPaymentMethods.orEmpty()),
    )

    private fun serializeMethods(
        methods: List<com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethod>,
    ): String {
        val array = JSONArray()
        methods.forEach { method ->
            array.put(com.adyen.checkout.core.components.data.model.paymentmethod.PaymentMethod.SERIALIZER.serialize(method))
        }
        return array.toString()
    }

    private fun serializeStoredMethods(
        methods: List<com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod>,
    ): String {
        val array = JSONArray()
        methods.forEach { method ->
            array.put(com.adyen.checkout.core.components.data.model.paymentmethod.StoredPaymentMethod.SERIALIZER.serialize(method))
        }
        return array.toString()
    }

    private fun CheckoutError.toPigeonError(): AdyenPigeonError =
        AdyenPigeonError(code = code, message = message)

    private fun Throwable.toPigeonError(): AdyenPigeonError = when (this) {
        is AdyenPigeonError -> this
        else -> AdyenPigeonError(
            code = "Generic",
            message = message ?: "Checkout failed.",
        )
    }
}
