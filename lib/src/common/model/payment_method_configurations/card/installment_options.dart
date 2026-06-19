/// Base sealed class for installment options.
///
/// Use [DefaultInstallmentOptions] for options that apply to all card brands,
/// or [CardBasedInstallmentOptions] for brand-specific options.
sealed class InstallmentOptions {
  /// Month values for installments. All values must be > 1.
  final List<int> values;

  /// Whether revolving payment is included as an option.
  final bool includesRevolving;

  InstallmentOptions({
    required this.values,
    this.includesRevolving = false,
  });
}

/// Default installment options applied to all card brands.
class DefaultInstallmentOptions extends InstallmentOptions {
  DefaultInstallmentOptions({
    required super.values,
    super.includesRevolving,
  });

  @override
  String toString() {
    return 'DefaultInstallmentOptions('
        'values: $values, '
        'includesRevolving: $includesRevolving)';
  }
}

/// Installment options for a specific card brand.
class CardBasedInstallmentOptions extends InstallmentOptions {
  /// Card brand identifier. Valid values:
  /// - "visa", "mc" (Mastercard), "amex", "diners", "discover",
  /// - "jcb", "maestro", "bcmc" (Bancontact), "cartebancaire"
  /// See: https://docs.adyen.com/development-resources/paymentmethodvariant
  final String cardBrand;

  CardBasedInstallmentOptions({
    required this.cardBrand,
    required super.values,
    super.includesRevolving,
  });

  @override
  String toString() {
    return 'CardBasedInstallmentOptions('
        'cardBrand: $cardBrand, '
        'values: $values, '
        'includesRevolving: $includesRevolving)';
  }
}
