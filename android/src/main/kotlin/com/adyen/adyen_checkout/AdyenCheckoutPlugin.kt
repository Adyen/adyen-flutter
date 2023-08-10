package com.adyen.adyen_checkout

import CheckoutPlatformInterface
import CheckoutResultFlutterInterface
import OrderResponseModel
import SessionDropInResultEnum
import SessionDropInResultModel
import SessionPaymentResultModel
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.adyen_checkout.Mapper.mapToOrderResponseModel
import com.adyen.adyen_checkout.Mapper.mapTopAmount
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.SessionDropInCallback
import com.adyen.checkout.dropin.SessionDropInResult
import com.adyen.checkout.sessions.core.SessionPaymentResult
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
        sessionDropInResult?.let {
            val result = when (it) {
                is SessionDropInResult.CancelledByUser -> SessionDropInResultModel(
                    SessionDropInResultEnum.CANCELLEDBYUSER
                )

                is SessionDropInResult.Error -> SessionDropInResultModel(
                    SessionDropInResultEnum.ERROR,
                    reason = it.reason
                )

                is SessionDropInResult.Finished -> {
                    SessionDropInResultModel(
                        SessionDropInResultEnum.FINISHED,
                        result = SessionPaymentResultModel(
                            it.result.sessionId,
                            it.result.sessionResult,
                            it.result.sessionData,
                            it.result.resultCode,
                            it.result.order?.mapToOrderResponseModel(),
                        )
                    )
                }
            }

            Log.d("SessionDropIn", "DropIn result: $it")
            checkoutResultFlutterInterface?.onSessionDropInResult(result) {}
        }
    }

    private fun teardown() {
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.removeObserver(it)
        }
        lifecycleReference = null
    }
}
