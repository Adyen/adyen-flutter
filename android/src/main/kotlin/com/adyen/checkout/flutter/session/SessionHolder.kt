package com.adyen.checkout.flutter.session

import com.adyen.checkout.core.common.CheckoutContext
import org.json.JSONObject

class SessionHolder(
    var sessionSetupResponse: JSONObject = JSONObject(),
//    var orderResponse: JSONObject? = null,
    var sessionCheckout: CheckoutContext.Sessions
) {
    fun reset() {
        sessionSetupResponse = JSONObject()
//        orderResponse = null
    }
}
