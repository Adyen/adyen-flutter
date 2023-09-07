import Foundation
@_spi(AdyenInternal)
import Adyen

struct PaymentComponentDataResponse : Encodable {
    
    let amount: Adyen.Amount?
    
    let paymentMethod: AnyEncodable?
    
    let storePaymentMethod: Bool?
    
    let order: PartialPaymentOrder?
    
    @available(*, deprecated, message: "This property is deprecated. Use the amount property if needed.")
    let amountToPay: Adyen.Amount?
    
    let installments: Installments?
    
    let supportNativeRedirect: Bool = false
    
    let shopperName: ShopperName?
    
    let emailAddress: String?
    
    let telephoneNumber: String?
    
    let browserInfo: BrowserInfo?
    
    let checkoutAttemptId: String?
    
    let billingAddress: PostalAddress?
    
    let deliveryAddress: PostalAddress?
    
    let socialSecurityNumber: String?
    
    let delegatedAuthenticationData: DelegatedAuthenticationData?
    
    enum CodingKeys: String, CodingKey {
        case amount, paymentMethod, storePaymentMethod, order, amountToPay, installments, supportNativeRedirect,shopperName,emailAddress, telephoneNumber, browserInfo, checkoutAttemptId, billingAddress, deliveryAddress, socialSecurityNumber, delegatedAuthenticationData
    }
}
