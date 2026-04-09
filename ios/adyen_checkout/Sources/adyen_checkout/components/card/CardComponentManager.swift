import Foundation

class CardComponentManager: BasePlatformViewManager<BaseCardComponent> {
    enum Constants {
        static let cardAdvancedComponentId = "CARD_ADVANCED_COMPONENT"
        static let cardSessionComponentId = "CARD_SESSION_COMPONENT"
    }

    @MainActor
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        if let currentComponent = currentBaseComponent as? AdvancedComponentProtocol {
            currentComponent.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }
}
