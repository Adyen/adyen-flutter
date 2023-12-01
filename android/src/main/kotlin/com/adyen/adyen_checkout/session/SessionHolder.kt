package com.adyen.adyen_checkout.session

import org.json.JSONObject

data class SessionHolder(
    private var _sessionSetupResponse: JSONObject = JSONObject(),
    private var _orderResponse: JSONObject? = null
) {
    val sessionSetupResponse: JSONObject get() = _sessionSetupResponse
    val orderResponse: JSONObject? get() = _orderResponse
    fun init(sessionSetupResponse: JSONObject, orderResponse: JSONObject?) {
        _sessionSetupResponse = sessionSetupResponse
        _orderResponse = orderResponse
    }
}
