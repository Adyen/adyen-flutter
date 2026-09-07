import Adyen
import AdyenComponents
import Foundation
import PassKit

extension ApplePayConfigurationDTO {
    func attachCallbacks(
        to configuration: ApplePayConfiguration,
        callbacksApi: CheckoutCallbacksFlutterApi,
        checkoutId: String,
        currencyCode: String
    ) -> ApplePayConfiguration {
        var configuration = configuration
        if hasOnSelectShippingMethod {
            configuration = attachShippingMethodCallback(
                to: configuration,
                callbacksApi: callbacksApi,
                checkoutId: checkoutId,
                currencyCode: currencyCode
            )
        }
        if hasOnSelectShippingContact {
            configuration = attachShippingContactCallback(
                to: configuration,
                callbacksApi: callbacksApi,
                checkoutId: checkoutId,
                currencyCode: currencyCode
            )
        }
        if hasOnChangeCouponCode {
            configuration = attachCouponCodeCallback(
                to: configuration,
                callbacksApi: callbacksApi,
                checkoutId: checkoutId,
                currencyCode: currencyCode
            )
        }
        if hasOnAuthorize {
            configuration = attachAuthorizationCallback(
                to: configuration,
                callbacksApi: callbacksApi,
                checkoutId: checkoutId,
                currencyCode: currencyCode
            )
        }
        return configuration
    }

    private func attachShippingMethodCallback(
        to configuration: ApplePayConfiguration,
        callbacksApi: CheckoutCallbacksFlutterApi,
        checkoutId: String,
        currencyCode: String
    ) -> ApplePayConfiguration {
        configuration.onSelectShippingMethod { method, currentItems in
            await withCheckedContinuation { continuation in
                callbacksApi.onApplePaySelectShippingMethod(
                    checkoutId: checkoutId,
                    shippingMethod: method.toCallbackDTO(currencyCode: currencyCode),
                    currentSummaryItems: currentItems.map { $0.toCallbackDTO(currencyCode: currencyCode) }
                ) { result in
                    switch result {
                    case let .success(update):
                        continuation.resume(returning: update.toCallbackShippingMethodUpdate())
                    case .failure:
                        continuation.resume(returning: PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: currentItems))
                    }
                }
            }
        }
    }

    private func attachShippingContactCallback(
        to configuration: ApplePayConfiguration,
        callbacksApi: CheckoutCallbacksFlutterApi,
        checkoutId: String,
        currencyCode: String
    ) -> ApplePayConfiguration {
        configuration.onSelectShippingContact { contact, currentItems in
            await withCheckedContinuation { continuation in
                callbacksApi.onApplePaySelectShippingContact(
                    checkoutId: checkoutId,
                    contact: contact.toCallbackDTO(),
                    currentSummaryItems: currentItems.map { $0.toCallbackDTO(currencyCode: currencyCode) }
                ) { result in
                    switch result {
                    case let .success(update):
                        continuation.resume(returning: update.toCallbackShippingContactUpdate())
                    case .failure:
                        continuation.resume(returning: PKPaymentRequestShippingContactUpdate(
                            errors: [NSError(domain: "AdyenCheckout", code: 1)],
                            paymentSummaryItems: currentItems,
                            shippingMethods: []
                        ))
                    }
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private func attachCouponCodeCallback(
        to configuration: ApplePayConfiguration,
        callbacksApi: CheckoutCallbacksFlutterApi,
        checkoutId: String,
        currencyCode: String
    ) -> ApplePayConfiguration {
        configuration.onChangeCouponCode { code, currentItems in
            await withCheckedContinuation { continuation in
                callbacksApi.onApplePayChangeCouponCode(
                    checkoutId: checkoutId,
                    couponCode: code,
                    currentSummaryItems: currentItems.map { $0.toCallbackDTO(currencyCode: currencyCode) }
                ) { result in
                    switch result {
                    case let .success(update):
                        continuation.resume(returning: update.toCallbackCouponCodeUpdate())
                    case .failure:
                        continuation.resume(returning: PKPaymentRequestCouponCodeUpdate(
                            errors: [NSError(domain: "AdyenCheckout", code: 1)],
                            paymentSummaryItems: currentItems,
                            shippingMethods: []
                        ))
                    }
                }
            }
        }
    }

    private func attachAuthorizationCallback(
        to configuration: ApplePayConfiguration,
        callbacksApi: CheckoutCallbacksFlutterApi,
        checkoutId: String,
        currencyCode: String
    ) -> ApplePayConfiguration {
        configuration.onAuthorize { payment in
            await withCheckedContinuation { continuation in
                callbacksApi.onApplePayAuthorize(
                    checkoutId: checkoutId,
                    payment: payment.toCallbackDTO(currencyCode: currencyCode)
                ) { result in
                    switch result {
                    case let .success(value):
                        continuation.resume(returning: value.toCallbackAuthorizationResult())
                    case .failure:
                        continuation.resume(returning: PKPaymentAuthorizationResult(status: .failure, errors: nil))
                    }
                }
            }
        }
    }
}

private extension PKShippingMethod {
    func toCallbackDTO(currencyCode: String) -> ApplePayShippingMethodDTO {
        ApplePayShippingMethodDTO(
            label: label,
            detail: detail ?? "",
            amount: amount.toCallbackDTO(currencyCode: currencyCode),
            identifier: identifier ?? "",
            startDate: nil,
            endDate: nil
        )
    }
}

private extension NSDecimalNumber {
    func toCallbackDTO(currencyCode: String) -> AmountDTO {
        AmountDTO(
            currency: currencyCode,
            value: Int64(AmountFormatter.minorUnitAmount(from: decimalValue, currencyCode: currencyCode))
        )
    }
}

private extension PKPaymentSummaryItem {
    func toCallbackDTO(currencyCode: String) -> ApplePaySummaryItemDTO {
        ApplePaySummaryItemDTO(
            label: label,
            amount: amount.toCallbackDTO(currencyCode: currencyCode),
            type: type == .pending ? .pending : .definite
        )
    }
}

private extension PKContact {
    func toCallbackDTO() -> ApplePayContactDTO {
        ApplePayContactDTO(
            phoneNumber: phoneNumber?.stringValue,
            emailAddress: emailAddress as String?,
            givenName: name?.givenName,
            familyName: name?.familyName,
            phoneticGivenName: name?.phoneticRepresentation?.givenName,
            phoneticFamilyName: name?.phoneticRepresentation?.familyName,
            addressLines: postalAddress?.street.components(separatedBy: "\\n"),
            subLocality: postalAddress?.subLocality,
            city: postalAddress?.city,
            postalCode: postalAddress?.postalCode,
            subAdministrativeArea: postalAddress?.subAdministrativeArea,
            administrativeArea: postalAddress?.state,
            country: postalAddress?.country,
            countryCode: postalAddress?.isoCountryCode
        )
    }
}

private extension PKPayment {
    func toCallbackDTO(currencyCode: String) -> ApplePayAuthorizedPaymentDTO {
        ApplePayAuthorizedPaymentDTO(
            token: token.paymentData.base64EncodedString(),
            network: token.paymentMethod.network?.rawValue ?? "",
            billingContact: billingContact?.toCallbackDTO(),
            shippingContact: shippingContact?.toCallbackDTO(),
            shippingMethod: shippingMethod?.toCallbackDTO(currencyCode: currencyCode)
        )
    }
}

private extension ApplePaySummaryItemDTO {
    func toCallbackSummaryItem() throws -> PKPaymentSummaryItem {
        PKPaymentSummaryItem(
            label: label,
            amount: AmountFormatter.decimalAmount(Int(amount.value), currencyCode: amount.currency),
            type: type == .pending ? .pending : .final
        )
    }
}

private extension ApplePayShippingMethodDTO {
    func toCallbackShippingMethod() throws -> PKShippingMethod {
        let method = PKShippingMethod()
        method.label = label
        method.detail = detail
        method.identifier = identifier
        method.amount = NSDecimalNumber(value: Double(amount.value) / 100.0)
        return method
    }
}

private extension ApplePayShippingMethodUpdateDTO {
    func toCallbackShippingMethodUpdate() -> PKPaymentRequestShippingMethodUpdate {
        PKPaymentRequestShippingMethodUpdate(
            paymentSummaryItems: summaryItems.compactMap { try? $0.toCallbackSummaryItem() }
        )
    }
}

private extension ApplePayShippingContactUpdateDTO {
    func toCallbackShippingContactUpdate() -> PKPaymentRequestShippingContactUpdate {
        PKPaymentRequestShippingContactUpdate(
            errors: errors?.compactMap { $0.toCallbackError() },
            paymentSummaryItems: summaryItems.compactMap { try? $0.toCallbackSummaryItem() },
            shippingMethods: shippingMethods?.compactMap { try? $0.toCallbackShippingMethod() } ?? []
        )
    }
}

@available(iOS 15.0, *)
private extension ApplePayCouponCodeUpdateDTO {
    func toCallbackCouponCodeUpdate() -> PKPaymentRequestCouponCodeUpdate {
        PKPaymentRequestCouponCodeUpdate(
            errors: errors?.compactMap { $0.toCallbackError() },
            paymentSummaryItems: summaryItems.compactMap { try? $0.toCallbackSummaryItem() },
            shippingMethods: shippingMethods?.compactMap { try? $0.toCallbackShippingMethod() } ?? []
        )
    }
}

private extension ApplePayAuthorizationResultDTO {
    func toCallbackAuthorizationResult() -> PKPaymentAuthorizationResult {
        PKPaymentAuthorizationResult(
            status: isSuccess ? .success : .failure,
            errors: errors?.compactMap { $0.toCallbackError() }
        )
    }
}

private extension ApplePayPaymentErrorDTO {
    func toCallbackError() -> Error {
        NSError(
            domain: "AdyenCheckout.ApplePay",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: localizedDescription]
        )
    }
}
