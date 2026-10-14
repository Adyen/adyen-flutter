import Adyen
import AdyenCheckout
import Flutter
import Foundation
import UIKit

@MainActor
final class CheckoutPaymentView: NSObject, FlutterPlatformView {
    private let params: CheckoutPaymentViewParamsDTO
    private let paymentMethodObject: [String: Any]?
    private let holder: CheckoutHolder
    private let events: ComponentPlatformEventHandler
    private let registry: CheckoutComponentRegistry
    private let wrapperView = ComponentWrapperView()
    private var component: CheckoutPaymentComponent?
    private var lastReportedHeight: Int?

    private var checkoutId: String {
        params.checkoutId
    }

    private var componentId: String {
        params.componentId
    }

    init(
        params: CheckoutPaymentViewParamsDTO,
        holder: CheckoutHolder,
        events: ComponentPlatformEventHandler,
        registry: CheckoutComponentRegistry
    ) {
        self.params = params
        self.paymentMethodObject = try? JSONSerialization.jsonObject(
            with: Data(params.paymentMethodJson.utf8)
        ) as? [String: Any]
        self.holder = holder
        self.events = events
        self.registry = registry
        super.init()
        setup()
    }

    func view() -> UIView {
        wrapperView
    }

    func dispose() {
        registry.remove(checkoutId: checkoutId, componentId: componentId)
        component?.viewController.willMove(toParent: nil)
        component?.viewController.removeFromParent()
        component = nil
        wrapperView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func setup() {
        do {
            guard let checkout = holder.checkout(for: checkoutId) else {
                throw AdyenPigeonError(code: ErrorCodes.checkoutNotFound, message: "Checkout is no longer active.", details: nil)
            }

            let paymentComponent = try createPaymentComponent(checkout: checkout)
            component = paymentComponent
            registry.register(
                checkoutId: checkoutId,
                componentId: componentId,
                component: paymentComponent
            )
            sendReady(requiresUserInteraction: paymentComponent.requiresUserInteraction)
            let viewController = paymentComponent.viewController
            wrapperView.resizeViewportCallback = { [weak self] in self?.sendResize() }
            wrapperView.addArrangedSubview(viewController.view)
            wrapperView.onMoveToWindow = { [weak self] in self?.attachToParentViewController() }
            sendResize()
        } catch {
            sendFailure(error)
        }
    }

    private func attachToParentViewController() {
        guard let child = component?.viewController, child.parent == nil, wrapperView.window != nil else { return }
        var responder: UIResponder? = wrapperView.next
        while let current = responder, !(current is UIViewController) {
            responder = current.next
        }
        guard let parent = responder as? UIViewController else { return }
        parent.addChild(child)
        child.didMove(toParent: parent)
    }

    private func createPaymentComponent(checkout: PaymentCheckout) throws -> CheckoutPaymentComponent {
        if params.isStoredPaymentMethod {
            guard let identifier = paymentMethodObject?["id"] as? String else {
                throw AdyenPigeonError(
                    code: ErrorCodes.invalidPaymentMethod,
                    message: "Stored payment method id is missing.",
                    details: nil
                )
            }
            return try checkout.createPaymentComponent(for: identifier)
        }
        guard let type = paymentMethodObject?["type"] as? String,
              let paymentMethodType = PaymentMethodType(rawValue: type) else {
            throw AdyenPigeonError(
                code: ErrorCodes.invalidPaymentMethod,
                message: "Payment method type is missing or unsupported.",
                details: nil
            )
        }
        return try checkout.createPaymentComponent(for: paymentMethodType)
    }

    private func sendReady(requiresUserInteraction: Bool) {
        events.send(event: CheckoutEventDTO(
            type: .componentReady,
            checkoutId: checkoutId,
            componentId: componentId,
            requiresUserInteraction: requiresUserInteraction
        ))
    }

    private func sendFailure(_ error: Error) {
        events.send(event: CheckoutEventDTO(
            type: .failure,
            checkoutId: checkoutId,
            componentId: componentId,
            errorCode: ErrorCodes.paymentMethodFailure,
            errorMessage: error.localizedDescription
        ))
    }

    private func measuredContentHeight() -> CGFloat {
        guard let view = component?.viewController.view else { return 0 }
        let preferred = component?.viewController.preferredContentSize.height ?? 0
        if preferred > 0 {
            return preferred
        }
        let width = wrapperView.bounds.width > 0
            ? wrapperView.bounds.width
            : wrapperView.window?.windowScene?.screen.bounds.width ?? 0
        guard width > 0 else { return 0 }
        let fitted = view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return fitted > 0 ? fitted : wrapperView.bounds.height
    }

    private func sendResize(height: Int? = nil) {
        let value = height ?? Int(measuredContentHeight().rounded(.up))
        guard value > 0, value != lastReportedHeight else { return }
        lastReportedHeight = value
        events.send(event: CheckoutEventDTO(
            type: .resize,
            checkoutId: checkoutId,
            componentId: componentId,
            height: Int64(value)
        ))
    }
}
