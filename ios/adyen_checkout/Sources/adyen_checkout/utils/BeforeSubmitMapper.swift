@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout

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
            street: street,
            apartment: apartment
        )
    }
}

extension ShopperName {
    func toDTO() -> ShopperNameDTO {
        ShopperNameDTO(
            firstName: firstName,
            lastName: lastName,
            infix: nil,
            gender: nil
        )
    }
}

extension AddressDTO {
    func fromDTO() -> PostalAddress {
        PostalAddress(
            city: city,
            country: country,
            houseNumberOrName: houseNumberOrName,
            postalCode: postalCode,
            stateOrProvince: stateOrProvince,
            street: street,
            apartment: apartment
        )
    }
}

extension BeforeSubmitDataDTO {
    /// `BeforeSubmitData` has no public initializer (only `public var` fields), so a `null`
    /// field from Dart is applied by mutating `original` rather than constructing a new
    /// instance. This also naturally matches the documented "null = keep original value"
    /// semantics of the callback.
    ///
    /// - TODO: v6 migration - ShopperName.infix/gender are not exposed on iOS yet;
    ///   BeforeSubmitDataDTO.shopperName.infix/gender are dropped here until the native SDK
    ///   gap is closed (tracked via ADR).
    func applied(to original: BeforeSubmitData) -> BeforeSubmitData {
        var updated = original
        if let billingAddress { updated.billingAddress = billingAddress.fromDTO() }
        if let deliveryAddress { updated.deliveryAddress = deliveryAddress.fromDTO() }
        if let shopperName, let firstName = shopperName.firstName, let lastName = shopperName.lastName {
            updated.shopperName = ShopperName(firstName: firstName, lastName: lastName)
        }
        if let shopperEmail { updated.shopperEmail = shopperEmail }
        return updated
    }
}

extension BeforeSubmitResultDTO {
    func mapToBeforeSubmitResult(original: BeforeSubmitData) -> BeforeSubmitResult {
        if isAborted {
            return .abort
        }
        guard let data else { return .abort }
        return .proceed(data: data.applied(to: original), sessionData: sessionData)
    }
}
