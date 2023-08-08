package com.adyen.adyen_checkout

import CheckoutPlatformApi
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.SessionDropInCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin : FlutterPlugin, ActivityAware {
    private val checkoutPlatformApi = CheckoutPlatformApiImpl()
    private var lifecycleReference: HiddenLifecycleReference? = null
    private var lifecycleObserver: LifecycleEventObserver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) =
        CheckoutPlatformApi.setUp(flutterPluginBinding.binaryMessenger, checkoutPlatformApi)

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) =
        CheckoutPlatformApi.setUp(binding.binaryMessenger, null)

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
                    val dropInSessionLauncher = DropIn.registerForDropInResult(fragmentActivity,
                        SessionDropInCallback { sessionDropInResult ->
                            sessionDropInResult?.let {

                            }
                        })
                    checkoutPlatformApi.dropInSessionLauncher = dropInSessionLauncher
                }

                else -> {}
            }
        }
    }

    private fun teardown() {
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.removeObserver(it)
        }
        lifecycleReference = null
    }
}
