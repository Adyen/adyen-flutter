import 'package:adyen_checkout/src/common/model/card_callbacks/bin_lookup_data.dart';

class CardCallbacks {
  void Function(List<BinLookupData>)? onBinLookup;
  void Function(String)? onBinValue;

  CardCallbacks({
    this.onBinLookup,
    this.onBinValue,
  });
}
