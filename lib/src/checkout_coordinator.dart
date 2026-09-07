import 'dart:async';
import 'dart:convert';

import 'checkout_gateway.dart';
import 'common/model/action.dart';
import 'common/model/checkout.dart';
import 'common/model/checkout_callbacks.dart';
import 'common/model/checkout_configuration.dart';
import 'common/model/checkout_error.dart';
import 'common/model/checkout_results.dart';
import 'common/model/cse/encrypted_card.dart';
import 'common/model/cse/unencrypted_card.dart';
import 'common/model/payment_methods.dart';
import 'common/model/session_response.dart';
import 'generated/platform_api.g.dart';
import 'util/dto_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CheckoutCoordinator {
  static CheckoutCoordinator? _shared;

  static CheckoutCoordinator get shared =>
      _shared ??= CheckoutCoordinator(gateway: NativeCheckoutGateway());

  static void replaceSharedForTesting(CheckoutGateway gateway) {
    _shared?._dispose();
    _shared = CheckoutCoordinator(gateway: gateway);
  }

  final CheckoutGateway gateway;
  final StreamController<CheckoutEventDTO> _eventController =
      StreamController<CheckoutEventDTO>.broadcast();
  final Map<String, _CheckoutRecord> _checkouts = <String, _CheckoutRecord>{};
  final Map<String, AdditionalDetailsCallback> _actionCallbacks =
      <String, AdditionalDetailsCallback>{};
  final Map<String, CheckoutError> _actionFailures = <String, CheckoutError>{};
  late final StreamSubscription<CheckoutEventDTO> _eventSubscription;
  bool _operationInProgress = false;
  int _idCounter = 0;

  CheckoutCoordinator({required this.gateway}) {
    CheckoutCallbacksFlutterApi.setUp(_CheckoutCallbacksApi(this));
    ActionOnlyFlutterApi.setUp(_ActionOnlyApi(this));
    _eventSubscription = gateway.events.listen(_handleEvent);
  }

  Stream<CheckoutEventDTO> get events => _eventController.stream;

  String nextComponentId() => _newId('component');

  bool requiresExternalController(String checkoutId) =>
      _checkouts[checkoutId]?.configuration.showSubmitButton == false;

  Future<SessionCheckout> setupSession({
    required SessionResponse sessionResponse,
    required CheckoutConfiguration configuration,
    required SessionCheckoutCallbacks callbacks,
  }) async {
    _reserveOperation();
    var completed = false;
    try {
      final result = await gateway.setupSession(
        sessionResponse.toDTO(),
        configuration.toDTO(),
      );
      _validateSetupResult(result);
      final methods = result.toPaymentMethods();
      final checkout = createSessionCheckout(
        id: result.checkoutId,
        paymentMethods: methods.regular,
        storedPaymentMethods: methods.stored,
        callbacks: callbacks,
        coordinator: this,
      );
      _checkouts[result.checkoutId] = _CheckoutRecord.session(
        checkout: checkout,
        callbacks: callbacks,
        configuration: configuration,
      );
      completed = true;
      return checkout;
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    } finally {
      if (!completed) _operationInProgress = false;
    }
  }

  Future<AdvancedCheckout> setupAdvanced({
    required PaymentMethods paymentMethods,
    required CheckoutConfiguration configuration,
    required AdvancedCheckoutCallbacks callbacks,
  }) async {
    _reserveOperation();
    var completed = false;
    try {
      final result = await gateway.setupAdvanced(
        jsonEncode(paymentMethods.toJson()),
        configuration.toDTO(),
      );
      _validateSetupResult(result);
      final checkout = createAdvancedCheckout(
        id: result.checkoutId,
        paymentMethods: paymentMethods.regular,
        storedPaymentMethods: paymentMethods.stored,
        callbacks: callbacks,
        coordinator: this,
      );
      _checkouts[result.checkoutId] = _CheckoutRecord.advanced(
        checkout: checkout,
        callbacks: callbacks,
        configuration: configuration,
      );
      completed = true;
      return checkout;
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    } finally {
      if (!completed) _operationInProgress = false;
    }
  }

  Future<AdvancedCheckoutResult> handleAction({
    required Action action,
    required CheckoutConfiguration configuration,
    required AdditionalDetailsCallback onAdditionalDetails,
  }) async {
    _reserveOperation();
    final actionId = _newId('action');
    _actionCallbacks[actionId] = onAdditionalDetails;
    try {
      final result = await gateway.handleAction(
        actionId,
        jsonEncode(action.data),
        configuration.toDTO(),
      );
      final failure = _actionFailures.remove(actionId);
      if (failure != null) throw failure;
      if (result.resultCode.isEmpty) {
        throw const CheckoutError(
          code: CheckoutError.genericCode,
          message: 'Native action handling returned no result code.',
        );
      }
      return AdvancedCheckoutResult(resultCode: result.resultCode);
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    } finally {
      _actionCallbacks.remove(actionId);
      _actionFailures.remove(actionId);
      _operationInProgress = false;
    }
  }

  Future<EncryptedCard> encryptCard({
    required UnencryptedCard card,
    required String publicKey,
  }) async {
    try {
      return (await gateway.encryptCard(card.toDTO(), publicKey)).toModel();
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    }
  }

  Future<String> encryptBin({
    required String bin,
    required String publicKey,
  }) async {
    try {
      return await gateway.encryptBin(bin, publicKey);
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    }
  }

  Future<bool> validateCardNumber({
    required String cardNumber,
    required bool enableLuhnCheck,
  }) =>
      gateway.validateCardNumber(cardNumber, enableLuhnCheck);

  Future<bool> validateCardExpiryDate({
    required String expiryMonth,
    required String expiryYear,
  }) async {
    if (!RegExp(r'^\d{2}$').hasMatch(expiryMonth) ||
        !RegExp(r'^\d{2}$').hasMatch(expiryYear)) {
      return false;
    }
    return gateway.validateCardExpiryDate(expiryMonth, expiryYear);
  }

  Future<bool> validateCardSecurityCode({
    required String securityCode,
    String? cardBrand,
  }) =>
      gateway.validateCardSecurityCode(securityCode, cardBrand);

  Future<String> getThreeDS2SdkVersion() => gateway.getThreeDS2SdkVersion();

  Future<void> enableConsoleLogging({required bool enabled}) =>
      gateway.enableConsoleLogging(enabled);

  void disposeCheckout(String checkoutId) {
    final record = _checkouts.remove(checkoutId);
    if (record == null) return;
    markFlowDisposed(record.checkout);
    record.disposed = true;
    _operationInProgress = false;
    unawaited(gateway
        .disposeCheckout(checkoutId)
        .catchError((Object error, StackTrace stackTrace) {
      _reportError(error, stackTrace);
    }));
  }

  void disposeComponent(String checkoutId, String componentId) {
    unawaited(
      gateway.disposeComponent(checkoutId, componentId).catchError(
            (Object error, StackTrace stackTrace) =>
                _reportError(error, stackTrace),
          ),
    );
  }

  void reportComponentFailure(String checkoutId, CheckoutError error) {
    _terminalFailure(checkoutId, error);
  }

  void _reserveOperation() {
    if (_operationInProgress ||
        _checkouts.isNotEmpty ||
        _actionCallbacks.isNotEmpty) {
      throw CheckoutError.alreadyActive();
    }
    _operationInProgress = true;
  }

  void _validateSetupResult(CheckoutSetupResultDTO result) {
    if (result.checkoutId.isEmpty ||
        result.regularPaymentMethodsJson.isEmpty ||
        result.storedPaymentMethodsJson.isEmpty) {
      throw const CheckoutError(
        code: CheckoutError.genericCode,
        message: 'Native checkout setup returned incomplete data.',
      );
    }
  }

  void _handleEvent(CheckoutEventDTO event) {
    if (!_eventController.isClosed) _eventController.add(event);
    switch (event.type) {
      case CheckoutEventTypeDTO.complete:
        _terminalComplete(event);
      case CheckoutEventTypeDTO.failure:
        _terminalFailure(
          event.checkoutId,
          CheckoutError(
            code: event.errorCode ?? CheckoutError.genericCode,
            message: event.errorMessage,
          ),
        );
      case CheckoutEventTypeDTO.componentReady:
      case CheckoutEventTypeDTO.resize:
      case CheckoutEventTypeDTO.binLookup:
      case CheckoutEventTypeDTO.binValue:
        break;
    }
  }

  void _terminalComplete(CheckoutEventDTO event) {
    final record = _checkouts[event.checkoutId];
    if (record == null || record.terminal || record.disposed) return;
    if (record.sessionCallbacks != null) {
      final resultCode = event.resultCode;
      final sessionId = event.sessionId;
      final sessionData = event.sessionData;
      if (resultCode == null || sessionId == null || sessionData == null) {
        _terminalFailure(
          event.checkoutId,
          const CheckoutError(
            code: CheckoutError.genericCode,
            message: 'Native session completion returned incomplete data.',
          ),
        );
        return;
      }
      _completeRecord(
        record,
        () => record.sessionCallbacks!.onComplete(
          SessionCheckoutResult(
            resultCode: resultCode,
            sessionId: sessionId,
            sessionData: sessionData,
          ),
        ),
      );
      return;
    }

    final resultCode = event.resultCode;
    if (resultCode == null) {
      _terminalFailure(
        event.checkoutId,
        const CheckoutError(
          code: CheckoutError.genericCode,
          message: 'Native completion returned no result code.',
        ),
      );
      return;
    }
    _completeRecord(
      record,
      () => record.advancedCallbacks!.onComplete(
        AdvancedCheckoutResult(resultCode: resultCode),
      ),
    );
  }

  void _terminalFailure(String checkoutId, CheckoutError error) {
    final record = _checkouts[checkoutId];
    if (record == null || record.terminal || record.disposed) return;
    _completeRecord(
      record,
      () => record.onFailure(error),
    );
  }

  void _completeRecord(_CheckoutRecord record, void Function() callback) {
    if (record.terminal || record.disposed) return;
    record.terminal = true;
    try {
      callback();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    } finally {
      disposeCheckout(record.checkout.id);
    }
  }

  Future<BeforeSubmitResultDTO> _onBeforeSubmit(
    String checkoutId,
    BeforeSubmitDataDTO data,
  ) async {
    final record = _checkouts[checkoutId];
    final beforeSubmit = record?.sessionCallbacks?.onBeforeSubmit;
    if (record == null || beforeSubmit == null) {
      return BeforeSubmitResultDTO(
        isAborted: false,
        data: data,
      );
    }
    try {
      return (await beforeSubmit(data.toModel())).toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _terminalFailure(
        checkoutId,
        CheckoutError.callbackFailure(cause: error),
      );
      return BeforeSubmitResultDTO(isAborted: true);
    }
  }

  Future<SubmitResultDTO> _onSubmit(
    String checkoutId,
    PaymentComponentDataDTO data,
  ) async {
    final callback = _checkouts[checkoutId]?.advancedCallbacks?.onSubmit;
    if (callback == null) {
      return SubmitResultDTO(
        type: SubmitResultTypeDTO.retry,
        errorMessage: 'Advanced checkout is not available.',
      );
    }
    try {
      return (await callback(data.fromDTO())).toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return SubmitResultDTO(
        type: SubmitResultTypeDTO.retry,
        errorMessage: error.toString(),
      );
    }
  }

  Future<AdditionalDetailsResultDTO> _onAdditionalDetails(
    String checkoutId,
    ActionComponentDataDTO data,
  ) async {
    final callback =
        _checkouts[checkoutId]?.advancedCallbacks?.onAdditionalDetails;
    if (callback == null) {
      return AdditionalDetailsResultDTO(resultCode: 'Error');
    }
    try {
      return (await callback(data.fromDTO())).toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _terminalFailure(
        checkoutId,
        CheckoutError.callbackFailure(cause: error),
      );
      return AdditionalDetailsResultDTO(resultCode: 'Error');
    }
  }

  Future<AdditionalDetailsResultDTO> _onActionAdditionalDetails(
    String actionId,
    ActionComponentDataDTO data,
  ) async {
    final callback = _actionCallbacks[actionId];
    if (callback == null) {
      return AdditionalDetailsResultDTO(resultCode: 'Error');
    }
    try {
      return (await callback(data.fromDTO())).toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _actionFailures[actionId] = CheckoutError.callbackFailure(cause: error);
      return AdditionalDetailsResultDTO(resultCode: 'Error');
    }
  }

  Future<ApplePayShippingMethodUpdateDTO> _onApplePaySelectShippingMethod(
    String checkoutId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) async {
    final callback = _checkouts[checkoutId]
        ?.configuration
        .applePayConfiguration
        ?.onSelectShippingMethod;
    if (callback == null) {
      return ApplePayShippingMethodUpdateDTO(
        summaryItems: currentSummaryItems,
      );
    }
    try {
      return (await callback(
        shippingMethod.toModel(),
        currentSummaryItems.map((item) => item.toModel()).toList(),
      ))
          .toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return ApplePayShippingMethodUpdateDTO(summaryItems: currentSummaryItems);
    }
  }

  Future<ApplePayShippingContactUpdateDTO> _onApplePaySelectShippingContact(
    String checkoutId,
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) async {
    final callback = _checkouts[checkoutId]
        ?.configuration
        .applePayConfiguration
        ?.onSelectShippingContact;
    if (callback == null) {
      return ApplePayShippingContactUpdateDTO(
        summaryItems: currentSummaryItems,
      );
    }
    try {
      return (await callback(
        contact.toModel(),
        currentSummaryItems.map((item) => item.toModel()).toList(),
      ))
          .toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return ApplePayShippingContactUpdateDTO(
          summaryItems: currentSummaryItems);
    }
  }

  Future<ApplePayCouponCodeUpdateDTO> _onApplePayChangeCouponCode(
    String checkoutId,
    String couponCode,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) async {
    final callback = _checkouts[checkoutId]
        ?.configuration
        .applePayConfiguration
        ?.onChangeCouponCode;
    if (callback == null) {
      return ApplePayCouponCodeUpdateDTO(summaryItems: currentSummaryItems);
    }
    try {
      return (await callback(
        couponCode,
        currentSummaryItems.map((item) => item.toModel()).toList(),
      ))
          .toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return ApplePayCouponCodeUpdateDTO(summaryItems: currentSummaryItems);
    }
  }

  Future<ApplePayAuthorizationResultDTO> _onApplePayAuthorize(
    String checkoutId,
    ApplePayAuthorizedPaymentDTO payment,
  ) async {
    final callback = _checkouts[checkoutId]
        ?.configuration
        .applePayConfiguration
        ?.onAuthorize;
    if (callback == null) {
      return ApplePayAuthorizationResultDTO(isSuccess: true);
    }
    try {
      return (await callback(payment.toModel())).toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return ApplePayAuthorizationResultDTO(
        isSuccess: false,
        errors: <ApplePayPaymentErrorDTO>[
          ApplePayPaymentErrorDTO(
            type: ApplePayPaymentErrorTypeDTO.unknown,
            localizedDescription: 'Apple Pay authorization failed.',
          ),
        ],
      );
    }
  }

  void _reportError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'adyen_checkout',
      ),
    );
  }

  CheckoutError _asCheckoutError(Object error, StackTrace stackTrace) {
    if (error is CheckoutError) return error;
    if (error is PlatformException) {
      return CheckoutError(
        code: error.code,
        message: error.message,
        cause: error,
      );
    }
    _reportError(error, stackTrace);
    return CheckoutError(
      code: CheckoutError.genericCode,
      message: error.toString(),
      cause: error,
    );
  }

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  void _dispose() {
    unawaited(_eventSubscription.cancel());
    unawaited(_eventController.close());
    CheckoutCallbacksFlutterApi.setUp(null);
    ActionOnlyFlutterApi.setUp(null);
  }
}

class _CheckoutRecord {
  final CheckoutFlow checkout;
  final SessionCheckoutCallbacks? sessionCallbacks;
  final AdvancedCheckoutCallbacks? advancedCallbacks;
  final CheckoutConfiguration configuration;
  bool terminal = false;
  bool disposed = false;

  _CheckoutRecord.session({
    required this.checkout,
    required SessionCheckoutCallbacks callbacks,
    required this.configuration,
  })  : sessionCallbacks = callbacks,
        advancedCallbacks = null;

  _CheckoutRecord.advanced({
    required this.checkout,
    required AdvancedCheckoutCallbacks callbacks,
    required this.configuration,
  })  : sessionCallbacks = null,
        advancedCallbacks = callbacks;

  void Function(CheckoutError) get onFailure =>
      sessionCallbacks?.onFailure ?? advancedCallbacks!.onFailure;
}

class _CheckoutCallbacksApi extends CheckoutCallbacksFlutterApi {
  final CheckoutCoordinator coordinator;

  _CheckoutCallbacksApi(this.coordinator);

  @override
  Future<BeforeSubmitResultDTO> onBeforeSubmit(
    String checkoutId,
    BeforeSubmitDataDTO data,
  ) =>
      coordinator._onBeforeSubmit(checkoutId, data);

  @override
  Future<SubmitResultDTO> onSubmit(
    String checkoutId,
    PaymentComponentDataDTO data,
  ) =>
      coordinator._onSubmit(checkoutId, data);

  @override
  Future<AdditionalDetailsResultDTO> onAdditionalDetails(
    String checkoutId,
    ActionComponentDataDTO data,
  ) =>
      coordinator._onAdditionalDetails(checkoutId, data);

  @override
  Future<ApplePayShippingMethodUpdateDTO> onApplePaySelectShippingMethod(
    String checkoutId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) =>
      coordinator._onApplePaySelectShippingMethod(
        checkoutId,
        shippingMethod,
        currentSummaryItems,
      );

  @override
  Future<ApplePayShippingContactUpdateDTO> onApplePaySelectShippingContact(
    String checkoutId,
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) =>
      coordinator._onApplePaySelectShippingContact(
        checkoutId,
        contact,
        currentSummaryItems,
      );

  @override
  Future<ApplePayCouponCodeUpdateDTO> onApplePayChangeCouponCode(
    String checkoutId,
    String couponCode,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) =>
      coordinator._onApplePayChangeCouponCode(
        checkoutId,
        couponCode,
        currentSummaryItems,
      );

  @override
  Future<ApplePayAuthorizationResultDTO> onApplePayAuthorize(
    String checkoutId,
    ApplePayAuthorizedPaymentDTO payment,
  ) =>
      coordinator._onApplePayAuthorize(checkoutId, payment);
}

class _ActionOnlyApi extends ActionOnlyFlutterApi {
  final CheckoutCoordinator coordinator;

  _ActionOnlyApi(this.coordinator);

  @override
  Future<AdditionalDetailsResultDTO> onAdditionalDetails(
    String actionId,
    ActionComponentDataDTO data,
  ) =>
      coordinator._onActionAdditionalDetails(actionId, data);
}
