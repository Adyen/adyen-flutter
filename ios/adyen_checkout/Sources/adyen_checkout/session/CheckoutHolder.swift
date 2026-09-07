import AdyenCheckout
import Foundation

@MainActor
final class CheckoutHolder {
    private var checkouts: [String: PaymentCheckout] = [:]
    private var activeActionId: String?
    var actionCheckout: ActionOnlyCheckout?

    var isActive: Bool {
        !checkouts.isEmpty || activeActionId != nil
    }

    func store(_ checkout: PaymentCheckout, id: String) {
        checkouts[id] = checkout
    }

    func checkout(for id: String) -> PaymentCheckout? {
        checkouts[id]
    }

    func removeCheckout(for id: String) {
        checkouts.removeValue(forKey: id)
    }

    func beginAction(id: String) -> Bool {
        guard !isActive else { return false }
        activeActionId = id
        return true
    }

    func endAction(id: String) {
        if activeActionId == id {
            activeActionId = nil
        }
        actionCheckout = nil
    }

    func clear() {
        checkouts.removeAll()
        activeActionId = nil
        actionCheckout = nil
    }
}
