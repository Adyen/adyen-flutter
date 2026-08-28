import Foundation
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
@_spi(AdyenInternal) import Adyen
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif

extension DropInPlatformApi: PartialPaymentDelegate {
    func checkBalance(with data: Adyen.PaymentComponentData, component: any Adyen.Component, completion: @escaping (Result<Adyen.Balance, any Error>) -> Void) {
        do {
            let checkoutEvent = try CheckoutEvent(
                type: CheckoutEventType.balanceCheck,
                data: data.jsonObject.toJsonStringRepresentation()
            )
            checkBalanceHandler = completion
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        } catch {
            completion(.failure(error))
        }
    }

    func requestOrder(for component: any Adyen.Component, completion: @escaping (Result<Adyen.PartialPaymentOrder, any Error>) -> Void) {
        requestOrderHandler = completion
        let checkoutEvent = CheckoutEvent(type: CheckoutEventType.requestOrder)
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }

    func cancelOrder(_ order: Adyen.PartialPaymentOrder, component: any Adyen.Component) {
        do {
            let cancelOrderData: [String: Any] = [
                Constants.orderKey: order.jsonObject,
                Constants.shouldUpdatePaymentMethodsKey: false
            ]
            let data = try JSONSerialization.data(withJSONObject: cancelOrderData, options: [])
            let cancelOrderDataString = String(data: data, encoding: .utf8)
            let checkoutEvent = CheckoutEvent(type: CheckoutEventType.cancelOrder, data: cancelOrderDataString)
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        } catch {
            adyenPrint(error.localizedDescription)
        }
    }

}
