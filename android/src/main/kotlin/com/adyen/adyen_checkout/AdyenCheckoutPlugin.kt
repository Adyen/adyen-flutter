package com.adyen.adyen_checkout

import CheckoutFlutterApi
import CheckoutPlatformInterface
import PaymentResult
import PaymentResultEnum
import PaymentResultModel
import PlatformCommunicationModel
import PlatformCommunicationType
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.adyen_checkout.utils.Constants.Companion.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import com.adyen.adyen_checkout.utils.Mapper.mapToOrderResponseModel
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.DropInCallback
import com.adyen.checkout.dropin.DropInResult
import com.adyen.checkout.dropin.SessionDropInCallback
import com.adyen.checkout.dropin.SessionDropInResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin : FlutterPlugin, ActivityAware {
    private var checkoutPlatformApi: CheckoutPlatformApi? = null
    private var checkoutFlutterApi: CheckoutFlutterApi? = null
    private var lifecycleReference: HiddenLifecycleReference? = null
    private var lifecycleObserver: LifecycleEventObserver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        checkoutFlutterApi = CheckoutFlutterApi(flutterPluginBinding.binaryMessenger)
        checkoutPlatformApi = CheckoutPlatformApi(checkoutFlutterApi)
        CheckoutPlatformInterface.setUp(flutterPluginBinding.binaryMessenger, checkoutPlatformApi)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CheckoutPlatformInterface.setUp(binding.binaryMessenger, null)
        checkoutFlutterApi = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = setupActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = teardown()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        setupActivity(binding)

    override fun onDetachedFromActivity() = teardown()

    private fun setupActivity(binding: ActivityPluginBinding) {
        if (binding.activity !is FragmentActivity) {
            throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        }

        val fragmentActivity = binding.activity as FragmentActivity
        checkoutPlatformApi?.activity = fragmentActivity
        lifecycleReference = binding.lifecycle as HiddenLifecycleReference
        lifecycleObserver = lifecycleEventObserver(fragmentActivity)
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.addObserver(it)
        }
    }

    private fun lifecycleEventObserver(fragmentActivity: FragmentActivity): LifecycleEventObserver {
        return LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_CREATE -> {
                    checkoutPlatformApi?.dropInSessionLauncher =
                        DropIn.registerForDropInResult(fragmentActivity, sessionDropInCallback())
                    checkoutPlatformApi?.dropInAdvancedFlowLauncher =
                        DropIn.registerForDropInResult(
                            fragmentActivity, dropInAdvancedFlowCallback
                        )
                }

                else -> {}
            }
        }
    }

    private fun sessionDropInCallback() = SessionDropInCallback { sessionDropInResult ->
        if (sessionDropInResult == null) {
            return@SessionDropInCallback
        }

        val mappedResult = when (sessionDropInResult) {
            is SessionDropInResult.CancelledByUser -> PaymentResult(
                PaymentResultEnum.CANCELLEDBYUSER
            )

            is SessionDropInResult.Error -> PaymentResult(
                PaymentResultEnum.ERROR, reason = sessionDropInResult.reason
            )

            is SessionDropInResult.Finished -> PaymentResult(
                PaymentResultEnum.FINISHED, result = with(sessionDropInResult.result) {
                    PaymentResultModel(
                        sessionId,
                        sessionData,
                        resultCode,
                        order?.mapToOrderResponseModel()
                    )
                }
            )
        }
        checkoutFlutterApi?.onDropInSessionResult(mappedResult) {}
    }

    private val dropInAdvancedFlowCallback = DropInCallback { dropInAdvancedFlowResult ->
        if (dropInAdvancedFlowResult == null) {
            return@DropInCallback
        }

        val mappedResult = when (dropInAdvancedFlowResult) {
            is DropInResult.CancelledByUser -> PaymentResult(
                PaymentResultEnum.CANCELLEDBYUSER
            )

            is DropInResult.Error -> PaymentResult(
                PaymentResultEnum.ERROR, reason = dropInAdvancedFlowResult.reason
            )

            is DropInResult.Finished -> PaymentResult(
                PaymentResultEnum.FINISHED, result = PaymentResultModel(
                    resultCode = dropInAdvancedFlowResult.result
                )
            )
        }

        val model = PlatformCommunicationModel(
            PlatformCommunicationType.RESULT, data = "", paymentResult = mappedResult
        )
        checkoutFlutterApi?.onDropInAdvancedFlowPlatformCommunication(model) {}
    }

    private fun teardown() {
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.removeObserver(it)
        }
        lifecycleReference = null
    }
}
