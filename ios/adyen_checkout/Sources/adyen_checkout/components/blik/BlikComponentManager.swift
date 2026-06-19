import Foundation

class BlikComponentManager: BasePlatformViewManager<BaseBlikComponent> {
    enum Constants {
        static let blikAdvancedComponentId = "BLIK_ADVANCED_COMPONENT"
        static let blikSessionComponentId = "BLIK_SESSION_COMPONENT"
    }

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        if let currentComponent = currentBaseComponent as? AdvancedComponentProtocol {
            currentComponent.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }
}
