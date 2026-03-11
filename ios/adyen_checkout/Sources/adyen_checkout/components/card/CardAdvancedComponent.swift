@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
import Flutter
import Foundation

class CardAdvancedComponent: BaseCardComponent, AdvancedComponentProtocol {
    private var actionComponentDelegate: ActionComponentDelegate?
    private var presentationDelegate: PresentationDelegate?
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
        setupCardComponentView()
    }

    private func setupCardComponentView() {
        do {
            let cardComponent = try setupCardComponent()
            actionComponent = buildActionComponent(adyenContext: cardComponent.context)
            showCardComponent(cardComponent: cardComponent)
            componentPlatformApi.register(cardBaseComponent: self)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent() throws -> CardComponent {
        componentDelegate = AdvancedFlowDelegate(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId
        )
        return try buildCardComponent(
            paymentMethodString: paymentMethod,
            isStoredPaymentMethod: isStoredPaymentMethod,
            cardComponentConfiguration: cardComponentConfiguration,
            componentDelegate: componentDelegate,
            cardDelegate: self
        )
    }

    private func buildActionComponent(adyenContext: AdyenContext) -> AdyenActionComponent {
        var configuration = AdyenActionComponent.Configuration()
        if let threeDS2Config = cardComponentConfiguration?.threeDS2ConfigurationDTO {
            configuration.threeDS = threeDS2Config.mapToThreeDS2Configuration()
        }
        let actionComponent = AdyenActionComponent(context: adyenContext, configuration: configuration)
        actionComponent.delegate = actionComponentDelegate
        actionComponent.presentationDelegate = getViewController()
        return actionComponent
    }

    func stopLoadingOnError() {
        cardComponent?.stopLoadingIfNeeded()
    }

    override func onDispose() {
        actionComponentDelegate = nil
        presentationDelegate = nil
        componentDelegate = nil
        actionComponent = nil
        super.onDispose()
    }
}
