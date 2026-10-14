package com.adyen.checkout.flutter

import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.DropInLauncher
import com.adyen.checkout.flutter.components.CheckoutComponentRegistry
import com.adyen.checkout.flutter.components.CheckoutPaymentViewFactory
import com.adyen.checkout.flutter.components.ComponentPlatformApi
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.generated.ActionOnlyFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutCallbacksFlutterApi
import com.adyen.checkout.flutter.generated.CheckoutHostApi
import com.adyen.checkout.flutter.generated.ComponentHostApi
import com.adyen.checkout.flutter.generated.EventsStreamHandler
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
    private var eventHandler: ComponentPlatformEventHandler? = null
    private var callbacksApi: CheckoutCallbacksFlutterApi? = null
    private var newIntentListener: Consumer<android.content.Intent>? = null
    private var dropInLauncher: DropInLauncher? = null
    private val checkoutHolder = CheckoutHolder()
    private val componentRegistry = CheckoutComponentRegistry()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        val eventHandler = ComponentPlatformEventHandler()
        val callbacksApi = CheckoutCallbacksFlutterApi(binding.binaryMessenger)
        this.eventHandler = eventHandler
        this.callbacksApi = callbacksApi
        EventsStreamHandler.register(binding.binaryMessenger, eventHandler)
        componentPlatformApi = ComponentPlatformApi(componentRegistry)
        ComponentHostApi.setUp(binding.binaryMessenger, componentPlatformApi)
        binding.platformViewRegistry.registerViewFactory(
            ComponentPlatformApi.VIEW_TYPE,
            CheckoutPaymentViewFactory(
                activityProvider = { activityPluginBinding?.activity as? FragmentActivity },
                checkoutHolder = checkoutHolder,
                callbacksApi = callbacksApi,
                eventHandler = eventHandler,
                registry = componentRegistry,
            ),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ComponentHostApi.setUp(binding.binaryMessenger, null)
        componentRegistry.clear()
        componentPlatformApi = null
        eventHandler = null
        callbacksApi = null
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
        val callbacksApi = callbacksApi ?: return
        val eventHandler = eventHandler ?: return
        // Drop-in launchers must be registered while the activity is being created, before it
        // reaches the STARTED state.
        dropInLauncher = DropIn.registerForResult(activity) { result ->
            checkoutPlatformApi?.onDropInResult(result)
        }
        setupPlatformCommunication(activity, pluginBinding.binaryMessenger, callbacksApi, eventHandler)
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
        callbacksApi: CheckoutCallbacksFlutterApi,
        eventHandler: ComponentPlatformEventHandler,
    ) {
        val actionOnlyApi = ActionOnlyFlutterApi(messenger)
        checkoutPlatformApi = CheckoutPlatformApi(
            activity = activity,
            checkoutHolder = checkoutHolder,
            callbacksApi = callbacksApi,
            actionOnlyApi = actionOnlyApi,
            eventHandler = eventHandler,
            dropInLauncher = dropInLauncher,
            componentRegistry = componentRegistry,
        )
        CheckoutHostApi.setUp(messenger, checkoutPlatformApi)
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
        dropInLauncher = null
        checkoutHolder.clear()
        flutterPluginBinding?.binaryMessenger?.let { messenger ->
            CheckoutHostApi.setUp(messenger, null)
        }
        activityPluginBinding = null
    }
}
