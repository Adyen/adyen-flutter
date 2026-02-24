package com.adyen.checkout.flutter.components

import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.OnPlatformEventStreamHandler
import com.adyen.checkout.flutter.generated.PigeonEventSink

class ComponentPlatformEventHandler : OnPlatformEventStreamHandler() {
    var eventSink: PigeonEventSink<ComponentCommunicationModel>? = null

    override fun onListen(
        p0: Any?,
        sink: PigeonEventSink<ComponentCommunicationModel>
    ) {
        eventSink = sink
    }

    override fun onCancel(args: Any?) {
        eventSink = null
    }
}
