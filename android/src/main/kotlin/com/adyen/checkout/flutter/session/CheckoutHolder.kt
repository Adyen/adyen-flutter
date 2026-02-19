package com.adyen.checkout.flutter.session

import com.adyen.checkout.core.common.CheckoutContext
import org.json.JSONObject

class CheckoutHolder(
    var sessionSetupResponse: JSONObject = JSONObject(),
    var checkoutContext: CheckoutContext? = null
) {
    fun reset() {
        sessionSetupResponse = JSONObject()
    }
}
