import 'package:adyen_checkout/src/common/model/card_callbacks/bin_lookup_data.dart';
import 'package:adyen_checkout/src/components/platform/base_platform_view_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

abstract class BaseCardComponent extends BasePlatformViewComponent {
  final CardComponentConfigurationDTO cardComponentConfiguration;
  final bool isStoredPaymentMethod;
  @override
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final void Function(List<BinLookupData>)? onBinLookup;
  final void Function(String)? onBinValue;

  BaseCardComponent({
    super.key,
    required this.cardComponentConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required super.initialViewHeight,
    required this.isStoredPaymentMethod,
    this.gestureRecognizers,
    this.onBinLookup,
    this.onBinValue,
    super.adyenLogger,
  });

  @override
  void handleAdditionalCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.binLookup) {
      _handleOnBinLookup(event);
    } else if (event.type case ComponentCommunicationType.binValue) {
      _handleOnBinValue(event);
    } else {
      handleComponentCommunication(event);
    }
  }

  void _handleOnBinLookup(ComponentCommunicationModel event) {
    if (onBinLookup == null) {
      return;
    }

    if (event.data case List<Object?> binLookupDataDTOList) {
      onBinLookup?.call(binLookupDataDTOList
          .whereType<BinLookupDataDTO>()
          .toBinLookupDataList());
    }
  }

  void _handleOnBinValue(ComponentCommunicationModel event) {
    if (onBinValue == null) {
      return;
    }

    if (event.data case String binValue) {
      onBinValue?.call(binValue);
    }
  }
}
