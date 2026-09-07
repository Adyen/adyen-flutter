import Adyen
import AdyenCheckout
import Foundation

extension BeforeSubmitData {
    func toDTO() -> BeforeSubmitDataDTO {
        BeforeSubmitDataDTO(
            billingAddress: billingAddress?.toDTO(),
            deliveryAddress: deliveryAddress?.toDTO(),
            shopperName: shopperName?.toDTO(),
            shopperEmail: shopperEmail
        )
    }
}

extension PostalAddress {
    func toDTO() -> AddressDTO {
        AddressDTO(
            city: city,
            country: country,
            houseNumberOrName: houseNumberOrName,
            postalCode: postalCode,
            stateOrProvince: stateOrProvince,
            street: street
        )
    }
}

extension ShopperName {
    func toDTO() -> ShopperNameDTO {
        ShopperNameDTO(firstName: firstName, lastName: lastName, infix: nil, gender: nil)
    }
}

extension AddressDTO {
    func toPostalAddress() -> PostalAddress {
        PostalAddress(
            city: city,
            country: country,
            houseNumberOrName: houseNumberOrName,
            postalCode: postalCode,
            stateOrProvince: stateOrProvince,
            street: street,
            apartment: nil
        )
    }
}

extension ShopperNameDTO {
    func toShopperName() -> ShopperName? {
        guard let firstName, let lastName else { return nil }
        return ShopperName(firstName: firstName, lastName: lastName)
    }
}

extension BeforeSubmitResultDTO {
    func toNativeResult(original: BeforeSubmitData) -> BeforeSubmitResult {
        if isAborted {
            return .abort
        }
        var updated = original
        if let data {
            if let billingAddress = data.billingAddress {
                updated.billingAddress = billingAddress.toPostalAddress()
            }
            if let deliveryAddress = data.deliveryAddress {
                updated.deliveryAddress = deliveryAddress.toPostalAddress()
            }
            if let shopperName = data.shopperName, let value = shopperName.toShopperName() {
                updated.shopperName = value
            }
            if let shopperEmail = data.shopperEmail {
                updated.shopperEmail = shopperEmail
            }
        }
        return .proceed(data: updated, sessionData: sessionData)
    }
}
