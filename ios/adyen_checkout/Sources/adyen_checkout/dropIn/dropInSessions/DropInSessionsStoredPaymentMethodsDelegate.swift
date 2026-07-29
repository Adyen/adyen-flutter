// TODO: v6 migration - DropIn has no public API on iOS in 6.0.0-alpha.1 (StoredPaymentMethodsDelegate
// is now package-access). All callers of this class are already commented out in DropInPlatformApi.swift.
// Restore once DropIn ships publicly on iOS.
// @_spi(AdyenInternal)
// import Adyen
// import UIKit
//
// class DropInSessionsStoredPaymentMethodsDelegate: StoredPaymentMethodsDelegate {
//     private let checkoutFlutter: CheckoutFlutterInterface
//     private let viewController: UIViewController
//     private var completionHandler: ((Bool) -> Void)?
//
//     init(viewController: UIViewController, checkoutFlutter: CheckoutFlutterInterface) {
//         self.checkoutFlutter = checkoutFlutter
//         self.viewController = viewController
//     }
//
//     func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
//         completionHandler = completion
//         let checkoutEvent = CheckoutEvent(
//             type: CheckoutEventType.deleteStoredPaymentMethod,
//             data: storedPaymentMethod.identifier
//         )
//         checkoutFlutter.send(
//             event: checkoutEvent,
//             completion: { _ in }
//         )
//     }
//
//     func handleDisableResult(isSuccessfullyRemoved: Bool) {
//         completionHandler?(isSuccessfullyRemoved)
//     }
// }
