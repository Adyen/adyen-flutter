import AdyenCheckout
import Foundation

@MainActor
final class ComponentPlatformApi: ComponentHostApi {
    private let registry = CheckoutComponentRegistry.shared

    func submit(
        checkoutId: String,
        componentId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let component = registry.setActive(checkoutId: checkoutId, componentId: componentId) else {
            completion(.failure(AdyenPigeonError(
                code: "ComponentNotFound",
                message: "Checkout component is no longer active.",
                details: nil
            )))
            return
        }
        component.submit()
        completion(.success(()))
    }

    func dispose(checkoutId: String, componentId: String) throws {
        registry.remove(checkoutId: checkoutId, componentId: componentId)
    }

    func handleReturn(url: URL) {
        registry.handleReturn(url: url)
    }

    func teardown() {
        registry.clear()
    }
}
