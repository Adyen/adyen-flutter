import Flutter
import Foundation

final class ComponentPlatformEventHandler: OnPlatformEventStreamHandler {
    private var eventSink: PigeonEventSink<ComponentCommunicationModel>?

    override func onListen(withArguments _: Any?, sink: PigeonEventSink<ComponentCommunicationModel>) {
        eventSink = sink
    }

    override func onCancel(withArguments _: Any?) {
        eventSink = nil
    }

    func send(event: ComponentCommunicationModel) {
        eventSink?.success(event)
    }
}
