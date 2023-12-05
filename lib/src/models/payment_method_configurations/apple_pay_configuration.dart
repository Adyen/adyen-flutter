class ApplePayConfiguration {
  final String merchantId;
  final String merchantName;
  final bool allowOnboarding;

  const ApplePayConfiguration({
    required this.merchantId,
    required this.merchantName,
    this.allowOnboarding = false,
  });
}
