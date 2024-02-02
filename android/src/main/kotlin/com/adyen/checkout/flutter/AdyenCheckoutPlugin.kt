package com.adyen.checkout.flutter

import CheckoutPlatformInterface
import ComponentFlutterInterface
import ComponentPlatformInterface
import DropInFlutterInterface
import DropInPlatformInterface
import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.components.card.CardComponentFactory
import com.adyen.checkout.flutter.components.card.CardComponentFactory.Companion.CARD_COMPONENT_ADVANCED
import com.adyen.checkout.flutter.components.card.CardComponentFactory.Companion.CARD_COMPONENT_SESSION
import com.adyen.checkout.flutter.dropIn.DropInPlatformApi
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants.Companion.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import com.adyen.checkout.flutter.utils.Constants.Companion.GOOGLE_PAY_REQUEST_CODE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.plugin.common.PluginRegistry

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {
    private var checkoutPlatformApi: CheckoutPlatformApi? = null
    private var dropInFlutterApi: DropInFlutterInterface? = null
    private var dropInPlatformApi: DropInPlatformApi? = null
    private var componentFlutterApi: ComponentFlutterInterface? = null
    private var componentPlatformApi: ComponentPlatformApi? = null
    private var lifecycleReference: HiddenLifecycleReference? = null
    private var lifecycleObserver: LifecycleEventObserver? = null
    private var flutterPluginBinding: FlutterPluginBinding? = null
    private var sessionHolder: SessionHolder = SessionHolder()
    private var activityPluginBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        checkoutPlatformApi = CheckoutPlatformApi(sessionHolder)
        CheckoutPlatformInterface.setUp(flutterPluginBinding.binaryMessenger, checkoutPlatformApi)

        // DropIn init
        dropInFlutterApi = DropInFlutterInterface(flutterPluginBinding.binaryMessenger)
        dropInFlutterApi?.let { dropInPlatformApi = DropInPlatformApi(it, sessionHolder) }
        DropInPlatformInterface.setUp(flutterPluginBinding.binaryMessenger, dropInPlatformApi)

        // Component init
        componentFlutterApi = ComponentFlutterInterface(flutterPluginBinding.binaryMessenger)
        componentPlatformApi = ComponentPlatformApi()
        ComponentPlatformInterface.setUp(flutterPluginBinding.binaryMessenger, componentPlatformApi)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        CheckoutPlatformInterface.setUp(binding.binaryMessenger, null)
        ComponentPlatformInterface.setUp(binding.binaryMessenger, null)
        dropInFlutterApi = null
        componentFlutterApi = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = setupActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = teardown()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = setupActivity(binding)

    override fun onDetachedFromActivity() = teardown()

    private fun setupActivity(binding: ActivityPluginBinding) {
        if (binding.activity !is FragmentActivity) {
            throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        }

        val fragmentActivity = binding.activity as FragmentActivity
        activityPluginBinding = binding
        activityPluginBinding?.addActivityResultListener(this)
        checkoutPlatformApi?.activity = fragmentActivity
        dropInPlatformApi?.activity = fragmentActivity
        lifecycleReference = binding.lifecycle as HiddenLifecycleReference
        lifecycleObserver = lifecycleEventObserver(fragmentActivity)
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.addObserver(it)
        }

        componentPlatformApi?.init(binding, sessionHolder)
        componentFlutterApi?.let {
            flutterPluginBinding?.apply {
                platformViewRegistry.registerViewFactory(
                    CARD_COMPONENT_ADVANCED,
                    CardComponentFactory(fragmentActivity, it, CARD_COMPONENT_ADVANCED)
                )

                platformViewRegistry.registerViewFactory(
                    CARD_COMPONENT_SESSION,
                    CardComponentFactory(fragmentActivity, it, CARD_COMPONENT_SESSION, sessionHolder)
                )
            }
        }
    }

    private fun lifecycleEventObserver(fragmentActivity: FragmentActivity): LifecycleEventObserver {
        return LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_CREATE -> {
                    dropInPlatformApi?.apply {
                        dropInSessionLauncher =
                            DropIn.registerForDropInResult(
                                fragmentActivity,
                                sessionDropInCallback,
                            )
                    }

                    dropInPlatformApi?.apply {
                        dropInAdvancedFlowLauncher =
                            DropIn.registerForDropInResult(
                                fragmentActivity,
                                dropInAdvancedFlowCallback,
                            )
                    }
                }

                else -> {}
            }
        }
    }

    private fun teardown() {
        activityPluginBinding?.removeActivityResultListener(this)
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.removeObserver(it)
        }
        lifecycleReference = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            GOOGLE_PAY_REQUEST_CODE -> {
                println("ON ACTIVITY RESULT GOOGLE PAY")
                componentPlatformApi?.googlePaySessionComponent?.handleActivityResult(resultCode, data)
                true
            }

            else -> {
                false
            }
        }
    }
}
