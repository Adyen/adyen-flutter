@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Flutter
import Foundation

class BlikAdvancedComponent: BaseBlikComponent, AdvancedComponentProtocol {
    private var actionComponentDelegate: ActionComponentDelegate?
    private var componentDelegate: PaymentComponentDelegate?
    private(set) var actionComponent: AdyenActionComponent?

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )

        actionComponentDelegate = ComponentActionHandler(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId,
            finalizeCallback: finalizeAndDismiss(success:completion:)
        )
        setupBlikComponentView()
    }

    private func setupBlikComponentView() {
        do {
            let blikComponent = try setupBlikComponent()
            actionComponent = AdyenActionComponent(context: blikComponent.context)
            actionComponent?.delegate = actionComponentDelegate
            actionComponent?.presentationDelegate = getViewController()
            showBlikComponent(blikComponent: blikComponent)
            componentPlatformApi.register(blikBaseComponent: self)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupBlikComponent() throws -> BLIKComponent {
        componentDelegate = AdvancedFlowDelegate(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId
        )
        return try buildBlikComponent(
            paymentMethodString: paymentMethod,
            blikComponentConfiguration: blikComponentConfiguration,
            componentDelegate: componentDelegate
        )
    }

    func stopLoadingOnError() {
        blikComponent?.stopLoadingIfNeeded()
    }

    override func onDispose() {
        actionComponentDelegate = nil
        componentDelegate = nil
        actionComponent = nil
        super.onDispose()
    }
}
