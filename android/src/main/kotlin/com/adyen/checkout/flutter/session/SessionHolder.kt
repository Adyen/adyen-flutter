package com.adyen.checkout.flutter.session

import org.json.JSONObject

class SessionHolder(
    var sessionSetupResponse: JSONObject = JSONObject(),
    var orderResponse: JSONObject? = null,
)
