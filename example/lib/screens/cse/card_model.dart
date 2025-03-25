class CardModel {
  final String cardNumber;

  CardModel({required this.cardNumber});

  CardModel copyWith({String? cardNumber}) {
    return CardModel(
      cardNumber: cardNumber ?? this.cardNumber,
    );
  }
}
