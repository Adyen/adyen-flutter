package com.adyen.adyen_checkout

import CheckoutPlatformApi
import DropInConfigurationModel
import SessionModel
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** AdyenCheckoutPlugin */
class AdyenCheckoutPlugin : FlutterPlugin, CheckoutPlatformApi {

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        CheckoutPlatformApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        CheckoutPlatformApi.setUp(binding.binaryMessenger, null)
    }

    override fun getPlatformVersion(callback: (Result<String>) -> Unit) {
        callback.invoke(Result.success("Android ${android.os.Build.VERSION.RELEASE}"))
    }

    override fun startPayment(
        sessionModel: SessionModel,
        dropInConfiguration: DropInConfigurationModel,
        callback: (Result<Unit>) -> Unit
    ) {
        TODO("Not yet implemented")
    }
}
