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
    private let wrapperView = ComponentWrapperView()
    private var component: CheckoutPaymentComponent?
    private var applePayButton: PKPaymentButton?

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
        events: ComponentPlatformEventHandler
    ) {
        self.params = params
        self.paymentMethodObject = try? JSONSerialization.jsonObject(
            with: Data(params.paymentMethodJson.utf8)
        ) as? [String: Any]
        self.holder = holder
        self.events = events
        super.init()
        setup()
    }

    func view() -> UIView {
        wrapperView
    }

    func dispose() {
        CheckoutComponentRegistry.shared.remove(checkoutId: checkoutId, componentId: componentId)
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
            CheckoutComponentRegistry.shared.register(
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
            CheckoutComponentRegistry.shared.register(
                checkoutId: checkoutId,
                componentId: componentId,
                component: paymentComponent
            )
            _ = CheckoutComponentRegistry.shared.setActive(
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
        case .black, nil: return .black
        }
    }

    private func mapApplePayButtonType(_ type: ApplePayButtonTypeDTO?) -> PKPaymentButtonType {
        switch type {
        case .plain, nil: return .plain
        case .buy: return .buy
        case .setUp: return .setUp
        case .inStore: return .inStore
        case .donate: return .donate
        case .checkout: return .checkout
        case .book: return .book
        case .subscribe: return .subscribe
        case .reload: return .reload
        case .addMoney: return .addMoney
        case .topUp: return .topUp
        case .order: return .order
        case .rent: return .rent
        case .support: return .support
        case .contribute: return .contribute
        case .tip: return .tip
        }
    }

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

    private func sendResize(height: Int? = nil) {
        let value = height ?? Int(component?.viewController.preferredContentSize.height ?? wrapperView.bounds.height)
        events.send(event: CheckoutEventDTO(
            type: .resize,
            checkoutId: checkoutId,
            componentId: componentId,
            height: Int64(value)
        ))
    }
}
