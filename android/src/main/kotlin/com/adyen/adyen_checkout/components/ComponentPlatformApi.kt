package com.adyen.adyen_checkout.components

import ComponentPlatformInterface
import org.json.JSONObject

class ComponentPlatformApi : ComponentPlatformInterface {
    override fun onAction(actionResponse: Map<String?, Any?>?) {
        actionResponse?.let {
            val jsonActionResponse = JSONObject(it)
            ComponentMessenger.sendResult(jsonActionResponse)
        }
    }
}