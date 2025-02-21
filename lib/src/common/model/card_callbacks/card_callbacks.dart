import 'package:adyen_checkout/src/common/model/card_callbacks/bin_lookup_data.dart';

abstract class CardCallbacksInterface {
  void Function(List<BinLookupData>)? onBinLookup;
  void Function(String)? onBinValue;
}

class CardCallbacks implements CardCallbacksInterface {
  CardCallbacks({
    this.onBinLookup,
    this.onBinValue,
  });

  @override
  void Function(List<BinLookupData>)? onBinLookup;

  @override
  void Function(String)? onBinValue;
}
