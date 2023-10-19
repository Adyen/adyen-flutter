class AmountNetworkModel {
  final String currency;
  final int value;

  AmountNetworkModel({
    required this.currency,
    required this.value,
  });

  factory AmountNetworkModel.fromJson(Map<String, dynamic> json) =>
      AmountNetworkModel(
        currency: json["currency"],
        value: json["value"],
      );

  Map<String, dynamic> toJson() => {
        "currency": currency,
        "value": value,
      };
}
