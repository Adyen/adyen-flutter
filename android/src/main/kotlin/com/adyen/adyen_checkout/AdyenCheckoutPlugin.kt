package com.adyen.adyen_checkout

import CheckoutPlatformInterface
import CheckoutResultFlutterInterface
import SessionDropInResultEnum
import SessionDropInResultModel
import SessionPaymentResultModel
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.adyen_checkout.Mapper.mapToOrderResponseModel
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.SessionDropInCallback
import com.adyen.checkout.dropin.SessionDropInResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin : FlutterPlugin, ActivityAware {
    private val checkoutPlatformApi = CheckoutPlatformApi()
    private var checkoutResultFlutterInterface: CheckoutResultFlutterInterface? = null
    private var lifecycleReference: HiddenLifecycleReference? = null
    private var lifecycleObserver: LifecycleEventObserver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        CheckoutPlatformInterface.setUp(
            flutterPluginBinding.binaryMessenger,
            checkoutPlatformApi
        )
        checkoutResultFlutterInterface =
            CheckoutResultFlutterInterface(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CheckoutPlatformInterface.setUp(binding.binaryMessenger, null)
        checkoutResultFlutterInterface = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = setupActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = teardown()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        setupActivity(binding)

    override fun onDetachedFromActivity() = teardown()

    private fun setupActivity(binding: ActivityPluginBinding) {
        val fragmentActivity = binding.activity as FragmentActivity
        checkoutPlatformApi.activity = fragmentActivity
        lifecycleReference = binding.lifecycle as HiddenLifecycleReference
        lifecycleObserver = lifecycleEventObserver(fragmentActivity)
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.addObserver(it)
        }
    }

    private fun lifecycleEventObserver(fragmentActivity: FragmentActivity): LifecycleEventObserver {
        return LifecycleEventObserver { source, event ->
            when (event) {
                Lifecycle.Event.ON_CREATE -> {
                    checkoutPlatformApi.dropInSessionLauncher =
                        DropIn.registerForDropInResult(fragmentActivity, sessionDropInCallback())
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
            is SessionDropInResult.CancelledByUser -> SessionDropInResultModel(
                SessionDropInResultEnum.CANCELLEDBYUSER
            )

            is SessionDropInResult.Error -> SessionDropInResultModel(
                SessionDropInResultEnum.ERROR,
                reason = sessionDropInResult.reason
            )

            is SessionDropInResult.Finished -> {
                SessionDropInResultModel(
                    SessionDropInResultEnum.FINISHED,
                    result = SessionPaymentResultModel(
                        sessionDropInResult.result.sessionId,
                        sessionDropInResult.result.sessionData,
                        sessionDropInResult.result.resultCode,
                        sessionDropInResult.result.order?.mapToOrderResponseModel(),
                    )
                )
            }
        }
        checkoutResultFlutterInterface?.onSessionDropInResult(mappedResult) {}
    }

    private fun teardown() {
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.removeObserver(it)
        }
        lifecycleReference = null
    }
}
