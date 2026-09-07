sealed class InstallmentOptions {
  final List<int> values;
  final bool includesRevolving;

  InstallmentOptions({
    required List<int> values,
    this.includesRevolving = false,
  }) : values = List<int>.unmodifiable(values);
}

class DefaultInstallmentOptions extends InstallmentOptions {
  DefaultInstallmentOptions({
    required super.values,
    super.includesRevolving,
  });

  @override
  String toString() =>
      'DefaultInstallmentOptions(values: $values, includesRevolving: $includesRevolving)';
}

class CardBasedInstallmentOptions extends InstallmentOptions {
  final String cardBrand;

  CardBasedInstallmentOptions({
    required this.cardBrand,
    required super.values,
    super.includesRevolving,
  });

  @override
  String toString() => 'CardBasedInstallmentOptions('
      'cardBrand: $cardBrand, '
      'values: $values, '
      'includesRevolving: $includesRevolving)';
}
