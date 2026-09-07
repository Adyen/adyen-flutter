import Foundation

final class ComponentPlatformEventHandler: EventsStreamHandler {
    private var eventSink: PigeonEventSink<CheckoutEventDTO>?

    override func onListen(withArguments _: Any?, sink: PigeonEventSink<CheckoutEventDTO>) {
        eventSink = sink
    }

    override func onCancel(withArguments _: Any?) {
        eventSink = nil
    }

    func send(event: CheckoutEventDTO) {
        eventSink?.success(event)
    }
}
