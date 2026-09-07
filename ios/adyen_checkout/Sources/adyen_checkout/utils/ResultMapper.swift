import Adyen
import AdyenCheckout
import Foundation

extension SubmitResultDTO {
    func toNativeResult() throws -> SubmitResult {
        switch type {
        case .completion:
            guard let resultCode else {
                throw AdyenPigeonError(
                    code: "InvalidSubmitResult",
                    message: "Submit completion did not contain a result code.",
                    details: nil
                )
            }
            return .completion(resultCode: resultCode)
        case .action:
            guard let actionJson,
                  let data = actionJson.data(using: .utf8) else {
                throw AdyenPigeonError(code: "InvalidSubmitResult", message: "Submit action did not contain action data.", details: nil)
            }
            return try .action(JSONDecoder().decode(Action.self, from: data))
        case .retry:
            return .retry(errorMessage: errorMessage)
        }
    }
}

extension PaymentCheckout {
    func setupResult(checkoutId: String) throws -> CheckoutSetupResultDTO {
        let methods = paymentMethods ?? PaymentMethods(regular: [], stored: [])
        let encoded = try JSONEncoder().encode(methods)
        guard let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any],
              let regular = object["paymentMethods"],
              let stored = object["storedPaymentMethods"] else {
            throw AdyenPigeonError(code: "InvalidPaymentMethods", message: "Unable to encode payment methods.", details: nil)
        }
        let regularData = try JSONSerialization.data(withJSONObject: regular)
        let storedData = try JSONSerialization.data(withJSONObject: stored)
        guard let regularJson = String(data: regularData, encoding: .utf8),
              let storedJson = String(data: storedData, encoding: .utf8) else {
            throw AdyenPigeonError(code: "InvalidPaymentMethods", message: "Unable to encode payment methods.", details: nil)
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
