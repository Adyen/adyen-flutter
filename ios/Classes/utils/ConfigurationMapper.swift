@_spi(AdyenInternal)
import Adyen
import PassKit

class ConfigurationMapper {
    
    func createDropInConfiguration(dropInConfigurationDTO: DropInConfigurationDTO) throws -> DropInComponent.Configuration {
        let dropInConfiguration = DropInComponent.Configuration(allowsSkippingPaymentList: dropInConfigurationDTO.skipListWhenSinglePaymentMethod,
                                                                allowPreselectedPaymentView: dropInConfigurationDTO.showPreselectedStoredPaymentMethod)
        
        dropInConfiguration.paymentMethodsList.allowDisablingStoredPaymentMethods = dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled
        
        if let cardsConfigurationDTO = dropInConfigurationDTO.cardsConfigurationDTO {
            let koreanAuthenticationMode = cardsConfigurationDTO.kcpFieldVisibility.toCardFieldVisibility()
            let socialSecurityNumberMode = cardsConfigurationDTO.socialSecurityNumberFieldVisibility.toCardFieldVisibility()
            let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: cardsConfigurationDTO.showCvcForStoredCard)
            let allowedCardTypes = determineAllowedCardTypes(cardTypes: cardsConfigurationDTO.supportedCardTypes)
            let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: cardsConfigurationDTO.addressMode)
            let cardConfiguration = DropInComponent.Card.init(
                showsHolderNameField: cardsConfigurationDTO.holderNameRequired,
                showsStorePaymentMethodField: cardsConfigurationDTO.showStorePaymentField,
                showsSecurityCodeField: cardsConfigurationDTO.showCvc,
                koreanAuthenticationMode: koreanAuthenticationMode,
                socialSecurityNumberMode: socialSecurityNumberMode,
                storedCardConfiguration: storedCardConfiguration,
                allowedCardTypes: allowedCardTypes,
                billingAddress: billingAddressConfiguration
            )
            
            dropInConfiguration.card = cardConfiguration
        }
        
        if let appleConfigurationDTO = dropInConfigurationDTO.applePayConfigurationDTO {
            let appleConfiguration = try buildApplePayConfiguration(applePayConfigurationDTO: appleConfigurationDTO, amount: dropInConfigurationDTO.amount, countryCode: dropInConfigurationDTO.countryCode)
            dropInConfiguration.applePay = appleConfiguration
        }
        
        if let cashAppPayConfigurationDTO = dropInConfigurationDTO.cashAppPayConfigurationDTO {
            dropInConfiguration.cashAppPay = DropInComponent.CashAppPay(redirectURL: URL(string: cashAppPayConfigurationDTO.returnUrl)!)
        }
        
        return dropInConfiguration
    }
    
    private func createStoredCardConfiguration(showCvcForStoredCard: Bool?) -> StoredCardConfiguration {
        var storedCardConfiguration = StoredCardConfiguration()
        storedCardConfiguration.showsSecurityCodeField = showCvcForStoredCard
        return storedCardConfiguration;
    }
    
    private func determineAllowedCardTypes(cardTypes: [String?]?) -> [CardType]? {
        guard let mappedCardTypes = cardTypes, !mappedCardTypes.isEmpty else {
            return nil
        }
        
        return mappedCardTypes.compactMap{$0}.map { CardType(rawValue: $0.lowercased()) }
    }
    
    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressConfiguration {
        var billingAddressConfiguration = BillingAddressConfiguration.init()
        switch addressMode {
        case .full:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.full
        case .postalCode:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.postalCode
        case .none?:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        default:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        }
        
        return billingAddressConfiguration
    }
    
    private func buildApplePayConfiguration(applePayConfigurationDTO: ApplePayConfigurationDTO, amount: AmountDTO, countryCode: String) throws -> Adyen.ApplePayComponent.Configuration {
        //TODO: Adjust pigeon code generation to use Int instead of Int64
        guard let value = Int(exactly: amount.value) else {
            throw PlatformError(errorDescription: "Cannot map Int64 to Int.")
        }
        let currencyCode = amount.currency
        let formattedAmount = AmountFormatter.decimalAmount(value,
                                                            currencyCode: currencyCode,
                                                            localeIdentifier: nil)
        
        let applePayPayment = try ApplePayPayment.init(countryCode: countryCode,
                                                       currencyCode: currencyCode,
                                                       summaryItems: [PKPaymentSummaryItem(label: applePayConfigurationDTO.merchantName, amount: formattedAmount)])
        
        return ApplePayComponent.Configuration.init(payment: applePayPayment,
                                                    merchantIdentifier: applePayConfigurationDTO.merchantId)
    }
}


extension FieldVisibility {
    
    func toCardFieldVisibility() -> CardComponent.FieldVisibility {
        switch self {
        case .show:
            return .show
        case .hide:
            return .hide
        }
    }
}
