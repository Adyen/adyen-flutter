import Adyen
import AdyenCheckout
import Flutter
import Foundation
import PassKit
import UIKit

@MainActor
final class CheckoutPaymentView: NSObject, FlutterPlatformView {
    private static let applePayButtonTypes: [String: PKPaymentButtonType] = [
        "buy": .buy,
        "setUp": .setUp,
        "inStore": .inStore,
        "donate": .donate,
        "checkout": .checkout,
        "book": .book,
        "subscribe": .subscribe,
        "reload": .reload,
        "addMoney": .addMoney,
        "topUp": .topUp,
        "order": .order,
        "rent": .rent,
        "support": .support,
        "contribute": .contribute,
        "tip": .tip
    ]

    private let checkoutId: String
    private let componentId: String
    private let paymentMethodJson: String
    private let isStoredPaymentMethod: Bool
    private let holder: CheckoutHolder
    private let events: ComponentPlatformEventHandler
    private let applePayButtonTheme: String?
    private let applePayButtonType: String?
    private let applePayButtonCornerRadius: Double?
    private let applePayButtonWidth: Double?
    private let applePayButtonHeight: Double?
    private let wrapperView = ComponentWrapperView()
    private var component: CheckoutPaymentComponent?
    private var applePayButton: PKPaymentButton?

    init(
        checkoutId: String,
        componentId: String,
        paymentMethodJson: String,
        isStoredPaymentMethod: Bool,
        applePayButtonTheme: String?,
        applePayButtonType: String?,
        applePayButtonCornerRadius: Double?,
        applePayButtonWidth: Double?,
        applePayButtonHeight: Double?,
        holder: CheckoutHolder,
        events: ComponentPlatformEventHandler
    ) {
        self.checkoutId = checkoutId
        self.componentId = componentId
        self.paymentMethodJson = paymentMethodJson
        self.isStoredPaymentMethod = isStoredPaymentMethod
        self.applePayButtonTheme = applePayButtonTheme
        self.applePayButtonType = applePayButtonType
        self.applePayButtonCornerRadius = applePayButtonCornerRadius
        self.applePayButtonWidth = applePayButtonWidth
        self.applePayButtonHeight = applePayButtonHeight
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
            if try isApplePayPaymentMethod(paymentMethodJson) {
                setupApplePayButton()
                sendReady(requiresUserInteraction: true)
                return
            }
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
            sendReady(requiresUserInteraction: paymentComponent.requiresUserInteraction)
            guard let viewController = paymentComponent.viewController else {
                sendResize(height: 0)
                return
            }
            wrapperView.resizeViewportCallback = { [weak self] in self?.sendResize() }
            wrapperView.addArrangedSubview(viewController.view)
            sendResize()
        } catch {
            sendFailure(error)
        }
    }

    private func isApplePayPaymentMethod(_ paymentMethodJson: String) throws -> Bool {
        let paymentMethod = try JSONSerialization.jsonObject(
            with: Data(paymentMethodJson.utf8)
        ) as? [String: Any]
        return paymentMethod?["type"] as? String == PaymentMethodType.applePay.rawValue
    }

    private func setupApplePayButton() {
        let buttonType = mapApplePayButtonType(applePayButtonType)
        let minimumWidth = buttonType == .plain ? 100.0 : 140.0
        let width = max(applePayButtonWidth ?? minimumWidth, minimumWidth)
        let height = max(applePayButtonHeight ?? 30.0, 30.0)
        let button = PKPaymentButton(
            paymentButtonType: buttonType,
            paymentButtonStyle: mapApplePayButtonStyle(applePayButtonTheme)
        )
        if let applePayButtonCornerRadius {
            button.cornerRadius = applePayButtonCornerRadius
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
            _ = CheckoutComponentRegistry.shared.setActive(
                checkoutId: checkoutId,
                componentId: componentId
            )
            guard let viewController = paymentComponent.viewController,
                  let presenter = presentingViewController else {
                throw AdyenPigeonError(
                    code: "PresentationFailure",
                    message: "Unable to present Apple Pay.",
                    details: nil
                )
            }
            presenter.present(viewController, animated: true)
        } catch {
            sendFailure(error)
        }
    }

    private var presentingViewController: UIViewController? {
        var viewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController
        while let presentedViewController = viewController?.presentedViewController {
            viewController = presentedViewController
        }
        return viewController
    }

    private func mapApplePayButtonStyle(_ style: String?) -> PKPaymentButtonStyle {
        switch style {
        case "white": return .white
        case "whiteOutline": return .whiteOutline
        case "automatic": return .automatic
        default: return .black
        }
    }

    private func mapApplePayButtonType(_ type: String?) -> PKPaymentButtonType {
        guard let type else { return .plain }
        return Self.applePayButtonTypes[type] ?? .plain
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
        let value = height ?? Int(component?.viewController?.preferredContentSize.height ?? wrapperView.bounds.height)
        events.send(event: CheckoutEventDTO(
            type: .resize,
            checkoutId: checkoutId,
            componentId: componentId,
            height: Int64(value)
        ))
    }
}
