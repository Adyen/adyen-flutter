import Adyen
import AdyenCheckout
import Flutter
import Foundation

@MainActor
final class CheckoutPaymentView: NSObject, FlutterPlatformView {
    private let checkoutId: String
    private let componentId: String
    private let holder: CheckoutHolder
    private let events: ComponentPlatformEventHandler
    private let wrapperView = ComponentWrapperView()
    private var component: CheckoutPaymentComponent?

    init(
        checkoutId: String,
        componentId: String,
        paymentMethodJson: String,
        isStoredPaymentMethod: Bool,
        holder: CheckoutHolder,
        events: ComponentPlatformEventHandler
    ) {
        self.checkoutId = checkoutId
        self.componentId = componentId
        self.holder = holder
        self.events = events
        super.init()
        setup(paymentMethodJson: paymentMethodJson, isStoredPaymentMethod: isStoredPaymentMethod)
    }

    func view() -> UIView {
        wrapperView
    }

    func dispose() {
        CheckoutComponentRegistry.shared.remove(checkoutId: checkoutId, componentId: componentId)
        component = nil
        wrapperView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func setup(paymentMethodJson: String, isStoredPaymentMethod: Bool) {
        do {
            guard let checkout = holder.checkout(for: checkoutId) else {
                throw AdyenPigeonError(code: "CheckoutNotFound", message: "Checkout is no longer active.", details: nil)
            }
            let paymentComponent = try createPaymentComponent(
                checkout: checkout,
                paymentMethodJson: paymentMethodJson,
                isStoredPaymentMethod: isStoredPaymentMethod
            )
            component = paymentComponent
            CheckoutComponentRegistry.shared.register(
                checkoutId: checkoutId,
                componentId: componentId,
                component: paymentComponent
            )
            events.send(event: CheckoutEventDTO(
                type: .componentReady,
                checkoutId: checkoutId,
                componentId: componentId,
                requiresUserInteraction: paymentComponent.requiresUserInteraction
            ))
            guard let viewController = paymentComponent.viewController else {
                sendResize(height: 0)
                return
            }
            wrapperView.resizeViewportCallback = { [weak self] in self?.sendResize() }
            wrapperView.addArrangedSubview(viewController.view)
            sendResize()
        } catch {
            events.send(event: CheckoutEventDTO(
                type: .failure,
                checkoutId: checkoutId,
                componentId: componentId,
                errorCode: "PaymentMethodFailure",
                errorMessage: error.localizedDescription
            ))
        }
    }

    private func createPaymentComponent(
        checkout: PaymentCheckout,
        paymentMethodJson: String,
        isStoredPaymentMethod: Bool
    ) throws -> CheckoutPaymentComponent {
        if isStoredPaymentMethod {
            guard let identifier = try JSONSerialization.jsonObject(
                with: Data(paymentMethodJson.utf8)
            ) as? [String: Any],
                let identifier = identifier["id"] as? String else {
                throw AdyenPigeonError(
                    code: "InvalidPaymentMethod",
                    message: "Stored payment method id is missing.",
                    details: nil
                )
            }
            return try checkout.createPaymentComponent(for: identifier)
        }
        let object = try JSONSerialization.jsonObject(with: Data(paymentMethodJson.utf8)) as? [String: Any]
        guard let type = object?["type"] as? String,
              let paymentMethodType = PaymentMethodType(rawValue: type) else {
            throw AdyenPigeonError(
                code: "InvalidPaymentMethod",
                message: "Payment method type is missing or unsupported.",
                details: nil
            )
        }
        return try checkout.createPaymentComponent(for: paymentMethodType)
    }

    private func sendResize(height: Int? = nil) {
        let value = height ?? Int(component?.viewController?.preferredContentSize.height ?? wrapperView.bounds.height)
        events.send(event: CheckoutEventDTO(
            type: .resize,
            checkoutId: checkoutId,
            componentId: componentId,
            height: Int64(value)
        ))
    }
}
