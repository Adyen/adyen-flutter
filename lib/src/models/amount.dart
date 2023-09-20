class Amount {
  final String? currency;
  final int value;

  Amount({
    this.currency,
    required this.value,
  });

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
      currency: json['currency'],
      value: json['value'],
    );
  }
}
