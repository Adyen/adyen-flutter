package com.adyen.checkout.flutter

import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ActionOnlyFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutHostApi
import com.adyen.checkout.flutter.generated.ComponentHostApi
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.Constants.WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger

class AdyenCheckoutPlugin : FlutterPlugin, ActivityAware {
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var checkoutPlatformApi: CheckoutPlatformApi? = null
    private var componentPlatformApi: ComponentPlatformApi? = null
    private var newIntentListener: Consumer<android.content.Intent>? = null
    private val checkoutHolder = CheckoutHolder()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        teardown()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivity() {
        teardown()
    }

    private fun attachActivity(binding: ActivityPluginBinding) {
        val activity = binding.activity as? FragmentActivity
            ?: throw Exception(WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE)
        activityPluginBinding = binding
        val pluginBinding = flutterPluginBinding ?: return
        setupPlatformCommunication(activity, pluginBinding.binaryMessenger, pluginBinding)
        val listener = Consumer<android.content.Intent> { intent: android.content.Intent ->
            checkoutPlatformApi?.handleReturn(intent)
            componentPlatformApi?.handleReturn(intent)
        }
        newIntentListener = listener
        activity.addOnNewIntentListener(listener)
    }

    private fun setupPlatformCommunication(
        activity: FragmentActivity,
        messenger: BinaryMessenger,
        pluginBinding: FlutterPlugin.FlutterPluginBinding,
    ) {
        val callbacksApi = CheckoutCallbacksFlutterApi(messenger)
        val actionOnlyApi = ActionOnlyFlutterApi(messenger)
        val eventHandler = ComponentPlatformEventHandler()
        checkoutPlatformApi = CheckoutPlatformApi(
            activity = activity,
            checkoutHolder = checkoutHolder,
            callbacksApi = callbacksApi,
            actionOnlyApi = actionOnlyApi,
            eventHandler = eventHandler,
        )
        CheckoutHostApi.setUp(messenger, checkoutPlatformApi)
        componentPlatformApi = ComponentPlatformApi(
            activity = activity,
            checkoutHolder = checkoutHolder,
            callbacksApi = callbacksApi,
            eventHandler = eventHandler,
            flutterPluginBinding = pluginBinding,
        )
        ComponentHostApi.setUp(messenger, componentPlatformApi)
    }

    private fun teardown() {
        newIntentListener?.let { listener ->
            (activityPluginBinding?.activity as? FragmentActivity)
                ?.removeOnNewIntentListener(listener)
        }
        newIntentListener = null
        componentPlatformApi?.teardown()
        checkoutPlatformApi?.teardown()
        checkoutPlatformApi = null
        componentPlatformApi = null
        checkoutHolder.clear()
        flutterPluginBinding?.binaryMessenger?.let { messenger ->
            CheckoutHostApi.setUp(messenger, null)
            ComponentHostApi.setUp(messenger, null)
        }
        activityPluginBinding = null
    }
}
