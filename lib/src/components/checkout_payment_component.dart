import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../checkout_controller.dart';
import '../checkout_runtime.dart';
import '../common/model/checkout.dart';
import '../common/model/checkout_error.dart';
import '../common/model/payment_method.dart';
import '../common/model/stored_payment_method.dart';
import '../generated/platform_api.g.dart';
import '../util/constants.dart';
import 'platform/android_platform_view.dart';
import 'component_container.dart';
import 'platform/ios_platform_view.dart';

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
  late CheckoutRuntime _runtime;
  late String _componentId;
  late CheckoutController _effectiveController;
  late StreamSubscription<CheckoutEventDTO> _eventSubscription;
  int? _viewportHeight;
  bool _hasError = false;

  // Approximate height of a button-only native component. Used as a provisional
  // height for no-interaction methods until the exact resize event arrives.
  static const int _buttonOnlyProvisionalHeight = 64;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateWidget(CheckoutPaymentComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final paymentMethodChanged =
        !identical(oldWidget.paymentMethod, widget.paymentMethod) &&
            jsonEncode(oldWidget.paymentMethod.data) !=
                jsonEncode(widget.paymentMethod.data);
    if (oldWidget.checkout.id != widget.checkout.id ||
        paymentMethodChanged ||
        oldWidget.controller != widget.controller) {
      _detach(
        checkout: oldWidget.checkout,
        ownController:
            oldWidget.controller == null ? _effectiveController : null,
      );
      _attach();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox.shrink();
    return ComponentContainer(
      initialViewPortHeight: _initialViewHeight,
      viewportHeight: _viewportHeight,
      componentWidget: _buildComponentWidget(),
    );
  }

  @override
  void dispose() {
    _detach(
      checkout: widget.checkout,
      ownController: widget.controller == null ? _effectiveController : null,
    );
    super.dispose();
  }

  void _attach() {
    _runtime = checkoutRuntimeOf(widget.checkout);
    _componentId = _runtime.nextComponentId();
    _viewportHeight = null;
    _hasError = false;
    _effectiveController = widget.controller ?? CheckoutController();
    attachCheckoutController(
      _effectiveController,
      () => _runtime.submitComponent(widget.checkout.id, _componentId),
    );
    _eventSubscription = _runtime.events
        .where(
          (event) =>
              event.checkoutId == widget.checkout.id &&
              event.componentId == _componentId,
        )
        .listen(_handleEvent);
  }

  void _detach({
    required CheckoutFlow checkout,
    required CheckoutController? ownController,
  }) {
    unawaited(_eventSubscription.cancel());
    _runtime.disposeComponent(checkout.id, _componentId);
    detachCheckoutController(_effectiveController);
    ownController?.dispose();
  }

  Widget _buildComponentWidget() {
    final creationParams = CheckoutPaymentViewParamsDTO(
      checkoutId: widget.checkout.id,
      componentId: _componentId,
      paymentMethodJson: jsonEncode(widget.paymentMethod.data),
      isStoredPaymentMethod: widget.paymentMethod is StoredPaymentMethod,
    );

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: ValueKey(_componentId),
          viewType: Constants.checkoutPaymentComponentViewType,
          creationParams: creationParams,
          codec: CheckoutHostApi.pigeonChannelCodec,
          gestureRecognizers: widget.gestureRecognizers,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: ValueKey(_componentId),
          viewType: Constants.checkoutPaymentComponentViewType,
          creationParams: creationParams,
          codec: CheckoutHostApi.pigeonChannelCodec,
          gestureRecognizers: widget.gestureRecognizers,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  double get _initialViewHeight {
    if (widget.paymentMethod is StoredPaymentMethod) return 80;
    return switch (widget.paymentMethod.type) {
      'scheme' => 320,
      'blik' => 220,
      // Button-only components are the common case on the v6 generic path;
      // unknown interactive methods grow from here instead of collapsing.
      _ => 64,
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
        _runtime.requiresExternalController(widget.checkout.id);
    if (needsController && widget.controller == null) {
      _runtime.reportComponentFailure(
        widget.checkout.id,
        const CheckoutError(
          code: CheckoutError.missingControllerCode,
          message:
              'A CheckoutController is required when showSubmitButton is false.',
        ),
      );
      setState(() => _hasError = true);
      return;
    }
    markCheckoutControllerReady(_effectiveController, requiresUserInteraction);
    if (requiresUserInteraction) return;
    if (needsController) {
      setState(() => _viewportHeight = 0);
    } else if (_viewportHeight == null) {
      // The native view is only a button; shorten the loading placeholder to a
      // button-sized height until the resize event reports the exact height.
      setState(() => _viewportHeight = _buttonOnlyProvisionalHeight);
    }
  }

  void _handleResize(int? height) {
    if (height == null || height == _viewportHeight) return;
    setState(() => _viewportHeight = height);
  }
}
