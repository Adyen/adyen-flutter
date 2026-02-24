import 'installment_options.dart';

class InstallmentConfiguration {
  final DefaultInstallmentOptions? defaultOptions;
  final List<CardBasedInstallmentOptions>? cardBasedOptions;
  final bool showInstallmentAmount;

  const InstallmentConfiguration({
    this.defaultOptions,
    this.cardBasedOptions,
    this.showInstallmentAmount = false,
  });

  @override
  String toString() {
    return 'InstallmentConfiguration('
        'defaultOptions: $defaultOptions, '
        'cardBasedOptions: $cardBasedOptions, '
        'showInstallmentAmount: $showInstallmentAmount)';
  }
}
