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
    private let paymentMethodJson: String
    private let isStoredPaymentMethod: Bool
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
        paymentMethodJson = arguments.value(forKey: "paymentMethod") as? String ?? ""
        isStoredPaymentMethod = arguments.value(forKey: "isStoredPaymentMethod") as? Bool ?? false
        componentId = arguments.value(forKey: "componentId") as? String ?? ""
        super.init()
        setupComponentView()
    }

    func view() -> UIView {
        componentWrapperView
    }

    func dispose() {
        V6ComponentControllerRegistry.shared.unregister(componentId: componentId)
    }

    private func setupComponentView() {
        do {
            guard let checkout = checkoutHolder.adyenCheckout else {
                throw PlatformError(errorDescription: "Checkout is not available.")
            }

            if let sessionCheckout = checkout as? SessionCheckout {
                _ = sessionCheckout.onBeforeSubmit { [weak self] data in
                    guard let self else { return .abort }
                    return await self.handleBeforeSubmit(data: data)
                }
            }

            let paymentComponent = try createPaymentComponent(checkout: checkout)

            self.paymentComponent = paymentComponent
            V6ComponentControllerRegistry.shared.register(componentId: componentId) { [weak self] in
                self?.paymentComponent
            }

            let requiresUserInteraction = paymentComponent.requiresUserInteraction
            sendComponentReady(requiresUserInteraction: requiresUserInteraction)

            if requiresUserInteraction {
                showComponent(paymentComponent: paymentComponent)
            } else {
                componentWrapperView.resizeViewportCallback = sendHeightUpdate
                sendHeightUpdate(viewHeight: 0)
            }
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    /// A stored payment method is targeted by its identifier (it does not appear in the
    /// regular payment methods list), while a regular payment method is targeted by its type.
    private func createPaymentComponent(checkout: PaymentCheckout) throws -> CheckoutPaymentComponent {
        if isStoredPaymentMethod {
            guard let identifier = storedPaymentMethodIdentifier else {
                throw PlatformError(errorDescription: "Stored payment method identifier not found.")
            }
            return try checkout.createPaymentComponent(for: identifier)
        }

        guard let paymentMethodType = PaymentMethodType(rawValue: paymentMethodTxVariant) else {
            throw PlatformError(errorDescription: "Unknown payment method type.")
        }
        return try checkout.createPaymentComponent(for: paymentMethodType)
    }

    /// The recurring detail reference (`id`) Adyen's `/paymentMethods` response uses to
    /// identify a stored payment method.
    private var storedPaymentMethodIdentifier: String? {
        guard let data = paymentMethodJson.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return jsonObject["id"] as? String
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

    private func sendComponentReady(requiresUserInteraction: Bool) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.componentReady,
            componentId: componentId,
            data: requiresUserInteraction
        )
        componentPlatformEventHandler.send(event: componentCommunicationModel)
    }

    private func sendHeightUpdate() {
        guard let viewHeight = paymentComponent?.viewController?.preferredContentSize.height else { return }
        sendHeightUpdate(viewHeight: Int(viewHeight))
    }

    private func sendHeightUpdate(viewHeight: Int) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.resize,
            componentId: componentId,
            data: viewHeight
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
