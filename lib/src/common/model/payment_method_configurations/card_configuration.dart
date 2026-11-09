import '../billing_address_mode.dart';
import '../field_visibility.dart';
import 'card/installment_configuration.dart';

class CardConfiguration {
  final BillingAddressMode billingAddressMode;
  final FieldVisibility koreanAuthenticationVisibility;
  final bool showCardholderName;
  final bool showSecurityCode;
  final bool showSecurityCodeForStoredCard;
  final bool showStorePaymentMethod;
  final bool showSupportedCardBrandLogos;
  final FieldVisibility socialSecurityNumberVisibility;
  final List<String>? supportedCardBrands;
  final InstallmentConfiguration? installmentConfiguration;

  const CardConfiguration({
    this.billingAddressMode = BillingAddressMode.none,
    this.koreanAuthenticationVisibility = FieldVisibility.auto,
    this.showCardholderName = false,
    this.showSecurityCode = true,
    this.showSecurityCodeForStoredCard = true,
    this.showStorePaymentMethod = true,
    this.showSupportedCardBrandLogos = true,
    this.socialSecurityNumberVisibility = FieldVisibility.auto,
    this.supportedCardBrands,
    this.installmentConfiguration,
  });

  @override
  String toString() => 'CardConfiguration('
      'billingAddressMode: $billingAddressMode, '
      'koreanAuthenticationVisibility: $koreanAuthenticationVisibility, '
      'showCardholderName: $showCardholderName, '
      'showSecurityCode: $showSecurityCode, '
      'showSecurityCodeForStoredCard: $showSecurityCodeForStoredCard, '
      'showStorePaymentMethod: $showStorePaymentMethod, '
      'showSupportedCardBrandLogos: $showSupportedCardBrandLogos, '
      'socialSecurityNumberVisibility: $socialSecurityNumberVisibility, '
      'supportedCardBrands: $supportedCardBrands, '
      'installmentConfiguration: $installmentConfiguration)';
}
