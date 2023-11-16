import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/adyen_component_api.dart';
import 'package:adyen_checkout/src/components/card/card_component_container_widget.dart';
import 'package:adyen_checkout/src/components/component_result_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/utils/constants.dart';
import 'package:adyen_checkout/src/utils/payment_flow_outcome_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

class CardAdvancedFlowWidget extends StatefulWidget {
  CardAdvancedFlowWidget({
    super.key,
    required this.cardComponentConfiguration,
    required this.paymentMethods,
    required this.onPayments,
    required this.onPaymentsDetails,
    required this.onPaymentResult,
    required this.initialViewHeight,
    PaymentFlowOutcomeHandler? paymentFlowOutcomeHandler,
    this.gestureRecognizers,
  }) : paymentFlowOutcomeHandler =
            paymentFlowOutcomeHandler ?? PaymentFlowOutcomeHandler();

  final CardComponentConfigurationDTO cardComponentConfiguration;
  final String paymentMethods;
  final Future<PaymentFlowOutcome> Function(String) onPayments;
  final Future<PaymentFlowOutcome> Function(String) onPaymentsDetails;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;
  final PaymentFlowOutcomeHandler paymentFlowOutcomeHandler;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<CardAdvancedFlowWidget> createState() => _CardAdvancedFlowWidgetState();
}

class _CardAdvancedFlowWidgetState extends State<CardAdvancedFlowWidget> {
  final MessageCodec<Object?> _codec = ComponentFlutterApi.codec;
  final ComponentResultApi _resultApi = ComponentResultApi();
  final StreamController<double> _resizeStream = StreamController.broadcast();
  final AdyenComponentApi _adyenComponentApi = AdyenComponentApi();
  final GlobalKey _cardWidgetKey = GlobalKey();
  late Widget _cardWidget;

  @override
  void initState() {
    super.initState();

    ComponentFlutterApi.setup(_resultApi);
    _cardWidget = _buildCardWidget();
    _resultApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen(_handleComponentCommunication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _resizeStream.stream
            .debounce(const Duration(milliseconds: 100))
            .distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return AdyenCardComponentContainerWidget(
            snapshot: snapshot,
            cardWidgetKey: _cardWidgetKey,
            initialViewHeight: widget.initialViewHeight,
            cardWidget: _cardWidget,
          );
        });
  }

  @override
  void dispose() {
    _resultApi.componentCommunicationStream.close();
    _resizeStream.close();
    super.dispose();
  }

  // ignore: unused_element
  // void _resetCardView() {
  //   setState(() {
  //     _cardView = _buildPlatformCardView();
  //   });
  // }

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
    }
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    final PaymentFlowOutcome paymentFlowOutcome =
        await widget.onPayments(event.data as String);
    _handlePaymentFlowOutcome(paymentFlowOutcome);
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    final PaymentFlowOutcome paymentFlowOutcome =
        await widget.onPaymentsDetails(event.data as String);
    _handlePaymentFlowOutcome(paymentFlowOutcome);
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }

  void _onResize(ComponentCommunicationModel event) =>
      _resizeStream.add(event.data as double);

  void _handlePaymentFlowOutcome(PaymentFlowOutcome paymentFlowOutcome) {
    final PaymentFlowOutcomeDTO paymentFlowOutcomeDTO = widget
        .paymentFlowOutcomeHandler
        .mapToPaymentOutcomeDTO(paymentFlowOutcome);
    switch (paymentFlowOutcomeDTO.paymentFlowResultType) {
      case PaymentFlowResultType.finished:
        _onPaymentFinished(paymentFlowOutcomeDTO);
      case PaymentFlowResultType.action:
        _onAction(paymentFlowOutcomeDTO);
      case PaymentFlowResultType.error:
        _onPaymentError(paymentFlowOutcomeDTO);
    }
  }

  void _onPaymentFinished(PaymentFlowOutcomeDTO paymentFlowOutcomeDTO) {
    String resultCode = paymentFlowOutcomeDTO.result ?? "";
    widget.onPaymentResult(PaymentAdvancedFlowFinished(resultCode: resultCode));
  }

  void _onAction(PaymentFlowOutcomeDTO paymentFlowOutcomeDTO) =>
      _adyenComponentApi.onAction(paymentFlowOutcomeDTO.actionResponse);

  void _onPaymentError(PaymentFlowOutcomeDTO paymentFlowOutcomeDTO) {
    String errorMessage = paymentFlowOutcomeDTO.error?.reason as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }

  Widget _buildCardWidget() {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      Constants.paymentMethodsKey: widget.paymentMethods,
      Constants.cardComponentConfigurationKey:
          widget.cardComponentConfiguration,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: UniqueKey(),
          viewType: Constants.cardComponentAdvancedFlowKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _adyenComponentApi.updateViewHeight,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: UniqueKey(),
          viewType: Constants.cardComponentAdvancedFlowKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _adyenComponentApi.updateViewHeight,
          cardWidgetKey: _cardWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
