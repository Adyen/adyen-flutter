import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_component_container.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

class CardAdvancedComponent extends StatefulWidget {
  final CardComponentConfigurationDTO cardComponentConfiguration;
  final String paymentMethod;
  final Future<PaymentEvent> Function(String) onPayments;
  final Future<PaymentEvent> Function(String) onPaymentsDetails;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final bool isStoredPaymentMethod;
  final double initialViewHeight;
  final PaymentEventHandler paymentEventHandler;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final AdyenLogger adyenLogger;
  final UniqueKey componentId = UniqueKey();

  CardAdvancedComponent({
    super.key,
    required this.cardComponentConfiguration,
    required this.paymentMethod,
    required this.onPayments,
    required this.onPaymentsDetails,
    required this.onPaymentResult,
    required this.initialViewHeight,
    required this.isStoredPaymentMethod,
    this.gestureRecognizers,
    PaymentEventHandler? paymentEventHandler,
    AdyenLogger? adyenLogger,
  })  : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler(),
        adyenLogger = adyenLogger ?? AdyenLogger.instance;

  @override
  State<CardAdvancedComponent> createState() => _CardAdvancedFlowState();
}

class _CardAdvancedFlowState extends State<CardAdvancedComponent> {
  final MessageCodec<Object?> _codec =
      ComponentFlutterInterface.pigeonChannelCodec;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;

  final StreamController<double> _resizeStream = StreamController.broadcast();
  final GlobalKey _cardWidgetKey = GlobalKey();
  late Widget _cardWidget;
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;

  @override
  void initState() {
    super.initState();

    _cardWidget = _buildCardWidget();
    _componentFlutterApi.componentCommunicationStream.stream
        .where((event) => event.componentId == widget.componentId.toString())
        .listen(_handleComponentCommunication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _resizeStream.stream
            .debounce(const Duration(milliseconds: 100))
            .distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return CardComponentContainer(
            snapshot: snapshot,
            cardWidgetKey: _cardWidgetKey,
            initialViewHeight: widget.initialViewHeight,
            cardWidget: _cardWidget,
          );
        });
  }

  @override
  void dispose() {
    _componentFlutterApi.dispose();
    _resizeStream.close();
    super.dispose();
  }

  void _handleComponentCommunication(event) async {
    switch (event.type) {
      case ComponentCommunicationType.onSubmit:
        _onSubmit(event);
      case ComponentCommunicationType.additionalDetails:
        _onAdditionalDetails(event);
      case ComponentCommunicationType.error:
        _onError(event);
      case ComponentCommunicationType.resize:
        _onResize(event);
      case ComponentCommunicationType.result:
        _onHandleResult(event);
    }
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await widget.onPayments(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        widget.paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    _componentPlatformApi.onPaymentsResult(paymentEventDTO);
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await widget.onPaymentsDetails(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        widget.paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    _componentPlatformApi.onPaymentsDetailsResult(paymentEventDTO);
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }

  void _onResize(ComponentCommunicationModel event) =>
      _resizeStream.add(event.data as double);

  void _onHandleResult(ComponentCommunicationModel event) {
    String resultCode = event.paymentResult?.resultCode ?? "";
    widget.adyenLogger.print("Card advanced flow result code: $resultCode");
    widget.onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  Widget _buildCardWidget() {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      Constants.paymentMethodKey: widget.paymentMethod,
      Constants.cardComponentConfigurationKey:
          widget.cardComponentConfiguration,
      Constants.isStoredPaymentMethodKey: widget.isStoredPaymentMethod,
      Constants.componentIdKey: widget.componentId.toString(),
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: widget.componentId,
          viewType: Constants.cardComponentAdvancedKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: widget.componentId,
          viewType: Constants.cardComponentAdvancedKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
          cardWidgetKey: _cardWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
