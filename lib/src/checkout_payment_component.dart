import 'dart:async';
import 'dart:convert';

import 'checkout_controller.dart';
import 'checkout_coordinator.dart';
import 'common/model/checkout.dart';
import 'common/model/checkout_error.dart';
import 'common/model/payment_method.dart';
import 'common/model/stored_payment_method.dart';
import 'components/platform/android_platform_view.dart';
import 'components/platform/component_container.dart';
import 'components/platform/ios_platform_view.dart';
import 'generated/platform_api.g.dart';
import 'util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class CheckoutPaymentComponent extends StatefulWidget {
  final CheckoutFlow checkout;
  final PaymentMethod paymentMethod;
  final CheckoutController? controller;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const CheckoutPaymentComponent({
    super.key,
    required this.checkout,
    required this.paymentMethod,
    this.controller,
    this.gestureRecognizers,
  });

  @override
  State<CheckoutPaymentComponent> createState() =>
      _CheckoutPaymentComponentState();
}

class _CheckoutPaymentComponentState extends State<CheckoutPaymentComponent> {
  final GlobalKey _componentWidgetKey = GlobalKey();
  late final CheckoutCoordinator _coordinator;
  late final String _componentId;
  late final CheckoutController _effectiveController;
  late final StreamSubscription<CheckoutEventDTO> _eventSubscription;
  late final Widget _componentWidget;
  int? _viewportHeight;
  int? _previousViewportHeight;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _coordinator = CheckoutCoordinator.shared;
    _componentId = _coordinator.nextComponentId();
    _effectiveController = widget.controller ?? CheckoutController();
    attachCheckoutController(
      _effectiveController,
      () => _coordinator.gateway.submit(widget.checkout.id, _componentId),
    );
    _eventSubscription = _coordinator.events
        .where(
          (event) =>
              event.checkoutId == widget.checkout.id &&
              event.componentId == _componentId,
        )
        .listen(_handleEvent);
    _componentWidget = _buildComponentWidget();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();
    return ComponentContainer(
      componentWidgetKey: _componentWidgetKey,
      initialViewPortHeight: _initialViewHeight,
      viewportHeight: _viewportHeight,
      componentWidget: _componentWidget,
    );
  }

  @override
  void dispose() {
    unawaited(_eventSubscription.cancel());
    _coordinator.disposeComponent(widget.checkout.id, _componentId);
    detachCheckoutController(_effectiveController);
    if (widget.controller == null) _effectiveController.dispose();
    super.dispose();
  }

  Widget _buildComponentWidget() {
    final creationParams = <String, dynamic>{
      Constants.checkoutIdKey: widget.checkout.id,
      Constants.componentIdKey: _componentId,
      Constants.paymentMethodKey: jsonEncode(widget.paymentMethod.data),
      Constants.isStoredPaymentMethodKey:
          widget.paymentMethod is StoredPaymentMethod,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          viewType: Constants.checkoutPaymentComponentViewType,
          creationParams: creationParams,
          codec: CheckoutHostApi.pigeonChannelCodec,
          gestureRecognizers: widget.gestureRecognizers,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: UniqueKey(),
          viewType: Constants.checkoutPaymentComponentViewType,
          creationParams: creationParams,
          codec: CheckoutHostApi.pigeonChannelCodec,
          gestureRecognizers: widget.gestureRecognizers,
          componentWidgetKey: _componentWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  double get _initialViewHeight {
    if (widget.paymentMethod is StoredPaymentMethod) return 80;
    return switch (widget.paymentMethod.type) {
      'googlepay' || 'paywithgoogle' || 'applepay' => 64,
      'blik' => 220,
      _ => 320,
    };
  }

  void _handleEvent(CheckoutEventDTO event) {
    if (!mounted) return;
    switch (event.type) {
      case CheckoutEventTypeDTO.componentReady:
        _handleReady(event.requiresUserInteraction);
      case CheckoutEventTypeDTO.resize:
        _handleResize(event.height);
      case CheckoutEventTypeDTO.failure:
        setState(() => _hasError = true);
      case CheckoutEventTypeDTO.binLookup:
      case CheckoutEventTypeDTO.binValue:
      case CheckoutEventTypeDTO.complete:
        break;
    }
  }

  void _handleReady(bool? requiresUserInteraction) {
    if (requiresUserInteraction == null) return;
    final needsController =
        _coordinator.requiresExternalController(widget.checkout.id) ||
            !requiresUserInteraction;
    if (needsController && widget.controller == null) {
      _coordinator.reportComponentFailure(
        widget.checkout.id,
        const CheckoutError(
          code: CheckoutError.missingControllerCode,
          message:
              'A CheckoutController is required for this payment method or when showSubmitButton is false.',
        ),
      );
      setState(() => _hasError = true);
      return;
    }
    markCheckoutControllerReady(_effectiveController, requiresUserInteraction);
    if (!requiresUserInteraction) setState(() => _viewportHeight = 0);
  }

  void _handleResize(int? height) {
    if (height == null || height == _previousViewportHeight) return;
    setState(() {
      _previousViewportHeight = height;
      _viewportHeight = height;
    });
  }
}
