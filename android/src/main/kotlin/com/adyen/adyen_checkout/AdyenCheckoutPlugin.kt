package com.adyen.adyen_checkout

import CheckoutFlutterApi
import CheckoutPlatformInterface
import DropInResultModel
import PlatformCommunicationModel
import SessionPaymentResultModel
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.adyen_checkout.Mapper.mapToOrderResponseModel
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
                            fragmentActivity, dropInAdvancedFlowCallback()
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
            is SessionDropInResult.CancelledByUser -> DropInResultModel(
                DropInResultEnum.CANCELLEDBYUSER
            )

            is SessionDropInResult.Error -> DropInResultModel(
                DropInResultEnum.ERROR, reason = sessionDropInResult.reason
            )

            is SessionDropInResult.Finished -> DropInResultModel(
                DropInResultEnum.FINISHED, result = SessionPaymentResultModel(
                    sessionDropInResult.result.sessionId,
                    sessionDropInResult.result.sessionData,
                    sessionDropInResult.result.resultCode,
                    sessionDropInResult.result.order?.mapToOrderResponseModel(),
                )
            )
        }
        checkoutFlutterApi?.onDropInSessionResult(mappedResult) {}
    }

    private fun dropInAdvancedFlowCallback() = DropInCallback { dropInAdvancedFlowResult ->
        if (dropInAdvancedFlowResult == null) {
            return@DropInCallback
        }

        val mappedResult = when (dropInAdvancedFlowResult) {
            is DropInResult.CancelledByUser -> DropInResultModel(
                DropInResultEnum.CANCELLEDBYUSER
            )

            is DropInResult.Error -> DropInResultModel(
                DropInResultEnum.ERROR, reason = dropInAdvancedFlowResult.reason
            )

            is DropInResult.Finished -> DropInResultModel(
                DropInResultEnum.FINISHED, result = SessionPaymentResultModel(
                    resultCode = dropInAdvancedFlowResult.result
                )
            )
        }

        val model = PlatformCommunicationModel(
            PlatformCommunicationType.RESULT, data = "", result = mappedResult
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
