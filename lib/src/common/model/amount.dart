class Amount {
  final int value;
  final String currency;

  const Amount({
    required this.value,
    required this.currency,
  });

  factory Amount.fromJson(Map<String, dynamic> json) => Amount(
        value: json['value'] as int,
        currency: json['currency'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'value': value,
        'currency': currency,
      };

  @override
  String toString() => 'Amount(value: $value, currency: $currency)';
}
