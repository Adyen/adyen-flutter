import Adyen
import AdyenCheckout
import Flutter
import Foundation
import PassKit
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
    private var applePayButton: PKPaymentButton?
    private var lastReportedHeight: Int?

    private var checkoutId: String {
        params.checkoutId
    }

    private var componentId: String {
        params.componentId
    }

    private var isApplePay: Bool {
        paymentMethodObject?["type"] as? String == PaymentMethodType.applePay.rawValue
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
        component = nil
        applePayButton = nil
        wrapperView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    private func setup() {
        do {
            if isApplePay {
                setupApplePayButton()
                sendReady(requiresUserInteraction: true)
                return
            }
            guard let checkout = holder.checkout(for: checkoutId) else {
                throw AdyenPigeonError(code: "CheckoutNotFound", message: "Checkout is no longer active.", details: nil)
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
            sendResize()
        } catch {
            sendFailure(error)
        }
    }

    private func setupApplePayButton() {
        let buttonStyle = params.applePayButtonStyle
        let buttonType = mapApplePayButtonType(buttonStyle?.type)
        let minimumWidth = buttonType == .plain ? 100.0 : 140.0
        let width = max(params.applePayButtonWidth ?? minimumWidth, minimumWidth)
        let height = max(params.applePayButtonHeight ?? 30.0, 30.0)
        let button = PKPaymentButton(
            paymentButtonType: buttonType,
            paymentButtonStyle: mapApplePayButtonStyle(buttonStyle?.theme)
        )
        if let cornerRadius = buttonStyle?.cornerRadius {
            button.cornerRadius = cornerRadius
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(
            self,
            action: #selector(presentApplePay),
            for: .touchUpInside
        )

        let container = UIView()
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: width),
            button.heightAnchor.constraint(equalToConstant: height),
            container.heightAnchor.constraint(equalToConstant: height)
        ])
        applePayButton = button
        wrapperView.addArrangedSubview(container)
        sendResize(height: Int(height))
    }

    @objc private func presentApplePay() {
        applePayButton?.isEnabled = false
        do {
            guard let checkout = holder.checkout(for: checkoutId) else {
                throw AdyenPigeonError(code: "CheckoutNotFound", message: "Checkout is no longer active.", details: nil)
            }
            let paymentComponent = try createPaymentComponent(checkout: checkout)
            component = paymentComponent
            registry.register(
                checkoutId: checkoutId,
                componentId: componentId,
                component: paymentComponent
            )
            _ = registry.setActive(
                checkoutId: checkoutId,
                componentId: componentId
            )
            let viewController = paymentComponent.viewController
            guard let presenter = presentingViewController else {
                throw AdyenPigeonError(
                    code: "PresentationFailure",
                    message: "Unable to present Apple Pay.",
                    details: nil
                )
            }
            presenter.present(viewController, animated: true) { [weak self] in
                self?.applePayButton?.isEnabled = true
            }
        } catch {
            applePayButton?.isEnabled = true
            sendFailure(error)
        }
    }

    private var presentingViewController: UIViewController? {
        (wrapperView.window?.rootViewController ?? UIViewController.keyWindowRoot)?.topPresenter
    }

    private func mapApplePayButtonStyle(_ theme: ApplePayButtonThemeDTO?) -> PKPaymentButtonStyle {
        switch theme {
        case .white: return .white
        case .whiteWithLine: return .whiteOutline
        case .automatic: return .automatic
        case .black, nil: return .black
        }
    }

    private func mapApplePayButtonType(_ type: ApplePayButtonTypeDTO?) -> PKPaymentButtonType {
        guard let type else { return .plain }
        return Self.applePayButtonTypes[type] ?? .plain
    }

    private static let applePayButtonTypes: [ApplePayButtonTypeDTO: PKPaymentButtonType] = [
        .plain: .plain,
        .buy: .buy,
        .setUp: .setUp,
        .inStore: .inStore,
        .donate: .donate,
        .checkout: .checkout,
        .book: .book,
        .subscribe: .subscribe,
        .reload: .reload,
        .addMoney: .addMoney,
        .topUp: .topUp,
        .order: .order,
        .rent: .rent,
        .support: .support,
        .contribute: .contribute,
        .tip: .tip
    ]

    private func createPaymentComponent(checkout: PaymentCheckout) throws -> CheckoutPaymentComponent {
        if params.isStoredPaymentMethod {
            guard let identifier = paymentMethodObject?["id"] as? String else {
                throw AdyenPigeonError(
                    code: "InvalidPaymentMethod",
                    message: "Stored payment method id is missing.",
                    details: nil
                )
            }
            return try checkout.createPaymentComponent(for: identifier)
        }
        guard let type = paymentMethodObject?["type"] as? String,
              let paymentMethodType = PaymentMethodType(rawValue: type) else {
            throw AdyenPigeonError(
                code: "InvalidPaymentMethod",
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
            errorCode: "PaymentMethodFailure",
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
