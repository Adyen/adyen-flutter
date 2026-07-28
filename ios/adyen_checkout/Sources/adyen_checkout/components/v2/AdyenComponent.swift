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

@MainActor
class AdyenComponent: NSObject, FlutterPlatformView {
    private let adyenFlutterInterface: AdyenFlutterInterface
    private let sessionCheckoutFlutterInterface: SessionCheckoutFlutterInterface
    private let componentPlatformEventHandler: ComponentPlatformEventHandler
    private let checkoutHolder: CheckoutHolder
    private let componentWrapperView: ComponentWrapperView
    private let paymentMethodTxVariant: String
    private let componentId: String

    private var paymentComponent: CheckoutPaymentComponent?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        adyenFlutterInterface: AdyenFlutterInterface,
        sessionCheckoutFlutterInterface: SessionCheckoutFlutterInterface,
        componentPlatformEventHandler: ComponentPlatformEventHandler,
        checkoutHolder: CheckoutHolder,
        viewTypeId: String
    ) {
        self.adyenFlutterInterface = adyenFlutterInterface
        self.sessionCheckoutFlutterInterface = sessionCheckoutFlutterInterface
        self.componentPlatformEventHandler = componentPlatformEventHandler
        self.checkoutHolder = checkoutHolder
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
            guard let checkout = checkoutHolder.adyenCheckout, let paymentMethodType: PaymentMethodType = PaymentMethodType(rawValue: paymentMethodTxVariant) else {
                throw PlatformError(errorDescription: "Checkout is not available.")
            }

            if let sessionCheckout = checkout as? SessionCheckout {
                _ = sessionCheckout.onBeforeSubmit { [weak self] data in
                    guard let self else { return .abort }
                    return await self.handleBeforeSubmit(data: data)
                }
            }

            let paymentComponent = try checkout.createPaymentComponent(for: paymentMethodType)
            
            self.paymentComponent = paymentComponent
            self.showComponent(paymentComponent: paymentComponent)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func handleBeforeSubmit(data: BeforeSubmitData) async -> BeforeSubmitResult {
        await withCheckedContinuation { continuation in
            sessionCheckoutFlutterInterface.onBeforeSubmit(data: data.toDTO()) { result in
                switch result {
                case let .success(response):
                    continuation.resume(returning: response.mapToBeforeSubmitResult(original: data))
                case .failure:
                    continuation.resume(returning: .abort)
                }
            }
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
