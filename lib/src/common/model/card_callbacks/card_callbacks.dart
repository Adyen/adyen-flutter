import 'bin_lookup_data.dart';

class CardCallbacks {
  final void Function(String bin)? onBinChange;
  final void Function(BinLookupData data)? onBinLookup;

  const CardCallbacks({
    this.onBinChange,
    this.onBinLookup,
  });
}
