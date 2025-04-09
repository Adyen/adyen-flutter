class Amount {
  final int value;
  final String currency;

  Amount({
    required this.value,
    required this.currency,
  });

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
      currency: json['currency'],
      value: json['value'],
    );
  }

  @override
  String toString() {
    return 'Amount(value: $value, currency: $currency)';
  }
}
