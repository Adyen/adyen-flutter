package com.adyen.checkout.flutter

import android.content.Intent
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.adyen.checkout.dropin.old.DropIn
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.dropIn.DropInPlatformApi
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.CheckoutFlutterInterface
import com.adyen.checkout.flutter.generated.CheckoutPlatformInterface
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.ComponentPlatformInterface
import com.adyen.checkout.flutter.generated.DropInPlatformInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.Constants.Companion.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.ActivityResultListener {
    private var flutterPluginBinding: FlutterPluginBinding? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var checkoutPlatformApi: CheckoutPlatformApi? = null
    private var checkoutFlutter: CheckoutFlutterInterface? = null
    private var dropInPlatformApi: DropInPlatformApi? = null
    private var componentFlutterApi: ComponentFlutterInterface? = null

    private var adyenFlutterInterface: AdyenFlutterInterface? = null
    private var componentPlatformApi: ComponentPlatformApi? = null
    private var lifecycleObserver: LifecycleEventObserver? = null
    private var checkoutHolder: CheckoutHolder = CheckoutHolder()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        flutterPluginBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attachActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = teardown()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = attachActivity(binding)

    override fun onDetachedFromActivity() = teardown()

    private fun attachActivity(binding: ActivityPluginBinding) {
        if (binding.activity !is FragmentActivity) {
            throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        }

        activityPluginBinding =
            binding.apply {
                addActivityResultListener(this@AdyenCheckoutPlugin)
            }

        flutterPluginBinding?.apply {
            val fragmentActivity = binding.activity as FragmentActivity
            setupDefaultPlatformCommunication(fragmentActivity, this.binaryMessenger)
            setUpDropIn(fragmentActivity, this.binaryMessenger)
            setupComponents(fragmentActivity, this.binaryMessenger)
        }
    }

    private fun setupDefaultPlatformCommunication(
        fragmentActivity: FragmentActivity,
        binaryMessenger: BinaryMessenger,
    ) {
        checkoutPlatformApi = CheckoutPlatformApi(fragmentActivity, checkoutHolder)
        CheckoutPlatformInterface.setUp(binaryMessenger, checkoutPlatformApi)
    }

    private fun setUpDropIn(
        fragmentActivity: FragmentActivity,
        binaryMessenger: BinaryMessenger,
    ) {
        checkoutFlutter =
            CheckoutFlutterInterface(binaryMessenger).apply {
                dropInPlatformApi = DropInPlatformApi(this, fragmentActivity, checkoutHolder)
                DropInPlatformInterface.setUp(binaryMessenger, dropInPlatformApi)
            }

        lifecycleObserver =
            createLifecycleEventObserver(fragmentActivity).apply {
                (activityPluginBinding?.activity as? FragmentActivity)?.lifecycle?.addObserver(this)
            }
    }

    private fun setupComponents(
        fragmentActivity: FragmentActivity,
        binaryMessenger: BinaryMessenger
    ) {
        componentFlutterApi = ComponentFlutterInterface(binaryMessenger)
        adyenFlutterInterface = AdyenFlutterInterface(binaryMessenger)
        componentPlatformApi = ComponentPlatformApi(
            fragmentActivity,
            checkoutHolder,
            componentFlutterApi!!,
            adyenFlutterInterface!!,
            flutterPluginBinding
        )
        ComponentPlatformInterface.setUp(binaryMessenger, componentPlatformApi)
    }

    private fun createLifecycleEventObserver(fragmentActivity: FragmentActivity): LifecycleEventObserver =
        LifecycleEventObserver { _, event ->
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

    private fun teardown() {
        flutterPluginBinding?.let {
            teardownDefaultCommunication(it.binaryMessenger)
            teardownDropIn(it.binaryMessenger)
            teardownComponents(it.binaryMessenger)
        }

        activityPluginBinding?.removeActivityResultListener(this)
        activityPluginBinding = null
    }

    private fun teardownDropIn(binaryMessenger: BinaryMessenger) {
        lifecycleObserver?.let {
            (activityPluginBinding?.activity as? FragmentActivity)?.lifecycle?.removeObserver(it)
        }

        lifecycleObserver = null
        dropInPlatformApi = null
        checkoutFlutter = null
        DropInPlatformInterface.setUp(binaryMessenger, null)
    }

    private fun teardownComponents(binaryMessenger: BinaryMessenger) {
        componentPlatformApi = null
        componentFlutterApi = null
        ComponentPlatformInterface.setUp(binaryMessenger, null)
    }

    private fun teardownDefaultCommunication(binaryMessenger: BinaryMessenger) {
        checkoutPlatformApi = null
        CheckoutPlatformInterface.setUp(binaryMessenger, null)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ): Boolean = componentPlatformApi?.handleActivityResult(requestCode, resultCode, data) ?: false
}
