@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import Flutter
import Foundation

#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenSession)
    import AdyenSession
#endif

class AdyenComponent: NSObject, FlutterPlatformView {
    private let adyenFlutterInterface: AdyenFlutterInterface
    private let componentPlatformEventHandler: ComponentPlatformEventHandler
    private let sessionHolder: SessionHolder
    private let componentWrapperView: ComponentWrapperView
    private let paymentMethodTxVariant: String
    private let componentId: String

    private var paymentComponent: CheckoutPaymentComponent?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        adyenFlutterInterface: AdyenFlutterInterface,
        componentPlatformEventHandler: ComponentPlatformEventHandler,
        sessionHolder: SessionHolder,
        viewTypeId: String
    ) {
        self.adyenFlutterInterface = adyenFlutterInterface
        self.componentPlatformEventHandler = componentPlatformEventHandler
        self.sessionHolder = sessionHolder
        componentWrapperView = .init()
        paymentMethodTxVariant = arguments.value(forKey: "paymentMethodTxVariant") as? String ?? ""
        componentId = arguments.value(forKey: "componentId") as? String ?? ""
        super.init()
        setupComponentView()
    }

    func view() -> UIView {
        componentWrapperView
    }

    private func setupComponentView() {
        do {
            guard let checkout = sessionHolder.adyenCheckout, let paymentMethodType: PaymentMethodType = PaymentMethodType(rawValue: paymentMethodTxVariant) else {
                throw PlatformError(errorDescription: "Checkout is not available.")
            }
            
            guard let paymentComponent = sessionHolder.adyenCheckout?.createPaymentComponent(for: paymentMethodType) else {
                throw PlatformError(errorDescription: "Payment component not available.")
            }
            
            self.paymentComponent = paymentComponent
            self.showComponent(paymentComponent: paymentComponent)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func showComponent(paymentComponent: CheckoutPaymentComponent) {
        guard let componentView = paymentComponent.viewController?.view else {
            sendErrorToFlutterLayer(errorMessage: "Component view not available.")
            return
        }
        componentWrapperView.resizeViewportCallback = sendHeightUpdate
        componentWrapperView.addArrangedSubview(componentView)
        sendHeightUpdate()
    }

    private func sendHeightUpdate() {
        guard let viewHeight = paymentComponent?.viewController?.preferredContentSize.height else { return }
        let roundedViewHeight = Int(viewHeight)
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.resize,
            componentId: componentId,
            data: roundedViewHeight
        )
        componentPlatformEventHandler.send(event: componentCommunicationModel)
    }

    private func sendErrorToFlutterLayer(errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: errorMessage
            )
        )
        componentPlatformEventHandler.send(event: componentCommunicationModel)
    }
}
