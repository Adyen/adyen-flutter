package com.adyen.adyen_checkout.session

import org.json.JSONObject

class SessionHolder(
    var sessionSetupResponse: JSONObject = JSONObject(),
    var orderResponse: JSONObject? = null,
)
