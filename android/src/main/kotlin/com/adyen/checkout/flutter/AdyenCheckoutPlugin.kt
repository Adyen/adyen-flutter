package com.adyen.checkout.flutter

import CheckoutPlatformInterface
import ComponentFlutterInterface
import ComponentPlatformInterface
import DropInFlutterInterface
import DropInPlatformInterface
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.components.card.CardComponentFactory
import com.adyen.checkout.flutter.components.card.CardComponentFactory.Companion.cardComponentAdvancedId
import com.adyen.checkout.flutter.components.card.CardComponentFactory.Companion.cardComponentSessionId
import com.adyen.checkout.flutter.dropIn.DropInPlatformApi
import com.adyen.checkout.flutter.session.SessionHolder
import com.adyen.checkout.flutter.utils.Constants.Companion.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin : FlutterPlugin, ActivityAware {
    private var checkoutPlatformApi: CheckoutPlatformApi? = null
    private var dropInFlutterApi: DropInFlutterInterface? = null
    private var dropInPlatformApi: DropInPlatformApi? = null
    private var componentFlutterApi: ComponentFlutterInterface? = null
    private var componentPlatformApi: ComponentPlatformApi? = null
    private var lifecycleReference: HiddenLifecycleReference? = null
    private var lifecycleObserver: LifecycleEventObserver? = null
    private var flutterPluginBinding: FlutterPluginBinding? = null
    private var sessionHolder: SessionHolder = SessionHolder()

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

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = setupActivity(
        binding
    )

    override fun onDetachedFromActivity() = teardown()

    private fun setupActivity(binding: ActivityPluginBinding) {
        if (binding.activity !is FragmentActivity) {
            throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        }

        val fragmentActivity = binding.activity as FragmentActivity
        checkoutPlatformApi?.activity = fragmentActivity
        dropInPlatformApi?.activity = fragmentActivity
        lifecycleReference = binding.lifecycle as HiddenLifecycleReference
        lifecycleObserver = lifecycleEventObserver(fragmentActivity)
        lifecycleObserver?.let {
            lifecycleReference?.lifecycle?.addObserver(it)
        }

        componentFlutterApi?.let {
            flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
                cardComponentAdvancedId,
                CardComponentFactory(fragmentActivity, it, cardComponentAdvancedId)
            )

            flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
                cardComponentSessionId,
                CardComponentFactory(fragmentActivity, it, cardComponentSessionId, sessionHolder)
            )
        }
    }

    private fun lifecycleEventObserver(fragmentActivity: FragmentActivity): LifecycleEventObserver {
        return LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_CREATE -> {
                    dropInPlatformApi?.sessionDropInCallback?.let {
                        dropInPlatformApi?.dropInSessionLauncher = DropIn.registerForDropInResult(fragmentActivity, it)
                    }

                    dropInPlatformApi?.dropInAdvancedFlowCallback?.let {
                        dropInPlatformApi?.dropInAdvancedFlowLauncher = DropIn.registerForDropInResult(
                            fragmentActivity, it
                        )
                    }
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
