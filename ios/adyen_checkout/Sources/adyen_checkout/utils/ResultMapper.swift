import Adyen
import AdyenCheckout
import Foundation

extension Checkout {
    func setupResult(checkoutId: String) throws -> CheckoutSetupResultDTO {
        let methods = PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
        let encoded = try JSONEncoder().encode(methods)
        guard let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
              let regular = object["paymentMethods"],
              let stored = object["storedPaymentMethods"] else {
            throw AdyenPigeonError(code: ErrorCodes.invalidPaymentMethods, message: "Unable to encode payment methods.", details: nil)
        }
        let regularData = try JSONSerialization.data(withJSONObject: regular)
        let storedData = try JSONSerialization.data(withJSONObject: stored)
        guard let regularJson = String(data: regularData, encoding: .utf8),
              let storedJson = String(data: storedData, encoding: .utf8) else {
            throw AdyenPigeonError(code: ErrorCodes.invalidPaymentMethods, message: "Unable to encode payment methods.", details: nil)
        }
        return CheckoutSetupResultDTO(
            checkoutId: checkoutId,
            regularPaymentMethodsJson: regularJson,
            storedPaymentMethodsJson: storedJson
        )
    }
}

extension SessionResponseDTO {
    func toSessionResponse() -> SessionResponse {
        SessionResponse(id: id, sessionData: sessionData)
    }
}
