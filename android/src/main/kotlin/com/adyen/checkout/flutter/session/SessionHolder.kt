package com.adyen.checkout.flutter.session

import com.adyen.checkout.core.common.CheckoutContext
import org.json.JSONObject

class SessionHolder(
    var sessionSetupResponse: JSONObject = JSONObject(),
    var sessionCheckout: CheckoutContext.Sessions? = null
) {
    fun reset() {
        sessionSetupResponse = JSONObject()
    }
}
