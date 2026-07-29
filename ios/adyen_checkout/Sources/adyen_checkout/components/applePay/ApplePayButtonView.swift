import Flutter
import PassKit
import UIKit

/// A thin native platform view wrapping PassKit's own `PKPaymentButton`.
///
/// This button is only a visible trigger: tapping it notifies Flutter (via
/// `ComponentPlatformEventHandler`) so the existing `InstantComponentManager`
/// flow can run the actual Apple Pay checkout. Apple Pay's native SDK
/// component has no embeddable inline view of its own (its only UI is the
/// full-screen `PKPaymentAuthorizationViewController` sheet), so - unlike
/// Card/Blik/Google Pay - it cannot be rendered through the generic
/// `AdyenComponentFactory`/`AdyenComponent` platform-view path.
@MainActor
final class ApplePayButtonView: NSObject, FlutterPlatformView {
    private let button: PKPaymentButton
    private let componentId: String
    private let componentPlatformEventHandler: ComponentPlatformEventHandler

    init(
        frame: CGRect,
        arguments args: [String: Any],
        componentPlatformEventHandler: ComponentPlatformEventHandler
    ) {
        componentId = args["componentId"] as? String ?? ""
        self.componentPlatformEventHandler = componentPlatformEventHandler

        let buttonType = Self.mapButtonType(args["type"] as? String)
        let buttonStyle = Self.mapButtonStyle(args["theme"] as? String)
        button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
        button.frame = frame
        if let cornerRadius = args["cornerRadius"] as? Double {
            button.cornerRadius = CGFloat(cornerRadius)
        }

        super.init()
        button.addTarget(self, action: #selector(onButtonPressed), for: .touchUpInside)
    }

    func view() -> UIView {
        button
    }

    @objc
    private func onButtonPressed() {
        let event = ComponentCommunicationModel(
            type: ComponentCommunicationType.buttonPressed,
            componentId: componentId
        )
        componentPlatformEventHandler.send(event: event)
    }

    private static func mapButtonType(_ value: String?) -> PKPaymentButtonType {
        switch value {
        case "buy": return .buy
        case "setUp": return .setUp
        case "inStore": return .inStore
        case "donate": return .donate
        case "checkout": return .checkout
        case "book": return .book
        case "subscribe": return .subscribe
        case "reload": return .reload
        case "addMoney": return .addMoney
        case "topUp": return .topUp
        case "order": return .order
        case "rent": return .rent
        case "support": return .support
        case "contribute": return .contribute
        case "tip": return .tip
        default: return .plain
        }
    }

    private static func mapButtonStyle(_ value: String?) -> PKPaymentButtonStyle {
        switch value {
        case "white": return .white
        case "whiteOutline": return .whiteOutline
        case "black": return .black
        default: return .automatic
        }
    }
}
