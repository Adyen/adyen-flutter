import 'package:adyen_checkout_example/screens/cse/card_model.dart';
import 'package:flutter/cupertino.dart';

class CardNotifier extends ValueNotifier<CardModel> {
  CardNotifier(super.value);

  void test() {
    value = value.copyWith(cardNumber: "");
  }
}