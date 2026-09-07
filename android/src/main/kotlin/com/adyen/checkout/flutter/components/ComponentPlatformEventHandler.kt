package com.adyen.checkout.flutter.components

import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.EventsStreamHandler
import com.adyen.checkout.flutter.generated.PigeonEventSink

internal class ComponentPlatformEventHandler : EventsStreamHandler() {
    var eventSink: PigeonEventSink<CheckoutEventDTO>? = null
        private set

    override fun onListen(arguments: Any?, sink: PigeonEventSink<CheckoutEventDTO>) {
        eventSink = sink
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun send(event: CheckoutEventDTO) {
        eventSink?.success(event)
    }
}
