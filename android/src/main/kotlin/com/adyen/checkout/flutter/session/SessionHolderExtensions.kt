package com.adyen.checkout.flutter.session

import com.adyen.checkout.core.Environment
import com.adyen.checkout.components.core.Order
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.SessionSetupResponse

fun SessionHolder.toCheckoutSession(
    environment: Environment,
    clientKey: String,
): CheckoutSession {
    val sessionSetupResponse = SessionSetupResponse.SERIALIZER.deserialize(sessionSetupResponse)
    val order = orderResponse?.let { Order.SERIALIZER.deserialize(it) }
    return CheckoutSession(
        sessionSetupResponse = sessionSetupResponse,
        order = order,
        environment = environment,
        clientKey = clientKey,
    )
}
