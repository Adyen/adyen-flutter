import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'common/model/action.dart';
import 'common/model/checkout.dart';
import 'common/model/checkout_callbacks.dart';
import 'common/model/checkout_configuration.dart';
import 'common/model/checkout_error.dart';
import 'common/model/checkout_results.dart';
import 'common/model/cse/encrypted_card.dart';
import 'common/model/cse/unencrypted_card.dart';
import 'common/model/payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import 'common/model/payment_methods.dart';
import 'common/model/session_response.dart';
import 'generated/platform_api.g.dart';
import 'util/dto_mapper.dart';

Stream<CheckoutEventDTO> _nativeCheckoutEvents() => events();

final class CheckoutRuntime {
  final CheckoutHostApi _checkoutHostApi;
  final ComponentHostApi _componentHostApi;
  final StreamController<CheckoutEventDTO> _eventController =
      StreamController<CheckoutEventDTO>.broadcast();
  _CheckoutRecord? _checkout;
  AdditionalDetailsCallback? _actionCallback;
  CheckoutError? _actionFailure;
  late final StreamSubscription<CheckoutEventDTO> _eventSubscription;
  int _idCounter = 0;

  CheckoutRuntime({
    CheckoutHostApi? checkoutHostApi,
    ComponentHostApi? componentHostApi,
    Stream<CheckoutEventDTO>? platformEvents,
  })  : _checkoutHostApi = checkoutHostApi ?? CheckoutHostApi(),
        _componentHostApi = componentHostApi ?? ComponentHostApi() {
    CheckoutCallbacksFlutterApi.setUp(_CheckoutCallbacksApi(this));
    ActionOnlyFlutterApi.setUp(_ActionOnlyApi(this));
    _eventSubscription =
        (platformEvents ?? _nativeCheckoutEvents()).listen(_handleEvent);
  }

  Stream<CheckoutEventDTO> get events => _eventController.stream;

  String nextComponentId() => _newId('component');

  bool requiresExternalController(String checkoutId) =>
      _recordFor(checkoutId)?.configuration.showSubmitButton == false;

  ApplePayConfiguration? applePayConfiguration(String checkoutId) =>
      _recordFor(checkoutId)?.configuration.applePayConfiguration;

  _CheckoutRecord? _recordFor(String checkoutId) =>
      _checkout?.checkout.id == checkoutId ? _checkout : null;

  Future<SessionCheckout> setupSession({
    required SessionResponse sessionResponse,
    required CheckoutConfiguration configuration,
    required SessionCheckoutCallbacks callbacks,
  }) async {
    try {
      final result = await _checkoutHostApi.setupSession(
        sessionResponse.toDTO(),
        configuration.toDTO(),
      );
      final methods = result.toPaymentMethods();
      final checkout = createSessionCheckout(
        id: result.checkoutId,
        paymentMethods: methods.regular,
        storedPaymentMethods: methods.stored,
        callbacks: callbacks,
        runtime: this,
      );
      _checkout = _CheckoutRecord.session(
        checkout: checkout,
        callbacks: callbacks,
        configuration: configuration,
      );
      return checkout;
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    }
  }

  Future<AdvancedCheckout> setupAdvanced({
    required PaymentMethods paymentMethods,
    required CheckoutConfiguration configuration,
    required AdvancedCheckoutCallbacks callbacks,
  }) async {
    try {
      final result = await _checkoutHostApi.setupAdvanced(
        jsonEncode(paymentMethods.toJson()),
        configuration.toDTO(),
      );
      final checkout = createAdvancedCheckout(
        id: result.checkoutId,
        paymentMethods: paymentMethods.regular,
        storedPaymentMethods: paymentMethods.stored,
        callbacks: callbacks,
        runtime: this,
      );
      _checkout = _CheckoutRecord.advanced(
        checkout: checkout,
        callbacks: callbacks,
        configuration: configuration,
      );
      return checkout;
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    }
  }

  Future<AdvancedCheckoutResult> handleAction({
    required Action action,
    required CheckoutConfiguration configuration,
    required AdditionalDetailsCallback onAdditionalDetails,
  }) async {
    final actionId = _newId('action');
    _actionCallback = onAdditionalDetails;
    try {
      final result = await _checkoutHostApi.handleAction(
        actionId,
        jsonEncode(action.data),
        configuration.toDTO(),
      );
      final failure = _actionFailure;
      _actionFailure = null;
      if (failure != null) throw failure;
      return AdvancedCheckoutResult(resultCode: result.resultCode);
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    } finally {
      _actionCallback = null;
      _actionFailure = null;
    }
  }

  Future<EncryptedCard> encryptCard({
    required UnencryptedCard card,
    required String publicKey,
  }) async {
    try {
      return (await _checkoutHostApi.encryptCard(card.toDTO(), publicKey))
          .toModel();
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    }
  }

  Future<String> encryptBin({
    required String bin,
    required String publicKey,
  }) async {
    try {
      return await _checkoutHostApi.encryptBin(bin, publicKey);
    } catch (error, stackTrace) {
      throw _asCheckoutError(error, stackTrace);
    }
  }

  Future<bool> validateCardNumber({
    required String cardNumber,
    required bool enableLuhnCheck,
  }) =>
      _checkoutHostApi.validateCardNumber(cardNumber, enableLuhnCheck);

  Future<bool> validateCardExpiryDate({
    required String expiryMonth,
    required String expiryYear,
  }) async {
    if (!RegExp(r'^\d{2}$').hasMatch(expiryMonth) ||
        !RegExp(r'^\d{2}$').hasMatch(expiryYear)) {
      return false;
    }
    return _checkoutHostApi.validateCardExpiryDate(expiryMonth, expiryYear);
  }

  Future<bool> validateCardSecurityCode({
    required String securityCode,
    String? cardBrand,
  }) =>
      _checkoutHostApi.validateCardSecurityCode(securityCode, cardBrand);

  Future<String> getThreeDS2SdkVersion() =>
      _checkoutHostApi.getThreeDS2SdkVersion();

  Future<void> enableConsoleLogging({required bool enabled}) =>
      _checkoutHostApi.enableConsoleLogging(enabled);

  void disposeCheckout(String checkoutId) {
    final record = _recordFor(checkoutId);
    if (record == null || record.disposed) return;
    _checkout = null;
    markFlowDisposed(record.checkout);
    record.disposed = true;
    unawaited(_checkoutHostApi
        .disposeCheckout(checkoutId)
        .catchError((Object error, StackTrace stackTrace) {
      _reportError(error, stackTrace);
    }));
  }

  Future<void> submitComponent(String checkoutId, String componentId) =>
      _componentHostApi.submit(checkoutId, componentId);

  void disposeComponent(String checkoutId, String componentId) {
    unawaited(
      _componentHostApi.dispose(checkoutId, componentId).catchError(
            (Object error, StackTrace stackTrace) =>
                _reportError(error, stackTrace),
          ),
    );
  }

  void reportComponentFailure(String checkoutId, CheckoutError error) {
    _terminalFailure(checkoutId, error);
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
    final record = _recordFor(event.checkoutId);
    if (record == null || record.terminal || record.disposed) return;
    if (record.sessionCallbacks != null) {
      final resultCode = event.resultCode;
      final sessionId = event.sessionId;
      final sessionResult = event.sessionResult;
      if (resultCode == null || sessionId == null || sessionResult == null) {
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
            sessionResult: sessionResult,
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
    final record = _recordFor(checkoutId);
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
    final record = _recordFor(checkoutId);
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
    final callback = _recordFor(checkoutId)?.advancedCallbacks?.onSubmit;
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
        _recordFor(checkoutId)?.advancedCallbacks?.onAdditionalDetails;
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
    final callback = _actionCallback;
    if (callback == null) {
      return AdditionalDetailsResultDTO(resultCode: 'Error');
    }
    try {
      return (await callback(data.fromDTO())).toDTO();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      _actionFailure = CheckoutError.callbackFailure(cause: error);
      return AdditionalDetailsResultDTO(resultCode: 'Error');
    }
  }

  Future<ApplePayShippingMethodUpdateDTO> _onApplePaySelectShippingMethod(
    String checkoutId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) async {
    final callback = _recordFor(checkoutId)
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
    final callback = _recordFor(checkoutId)
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
    final callback = _recordFor(checkoutId)
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
    final callback = _recordFor(checkoutId)
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

  void dispose() {
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
  final CheckoutRuntime runtime;

  _CheckoutCallbacksApi(this.runtime);

  @override
  Future<BeforeSubmitResultDTO> onBeforeSubmit(
    String checkoutId,
    BeforeSubmitDataDTO data,
  ) =>
      runtime._onBeforeSubmit(checkoutId, data);

  @override
  Future<SubmitResultDTO> onSubmit(
    String checkoutId,
    PaymentComponentDataDTO data,
  ) =>
      runtime._onSubmit(checkoutId, data);

  @override
  Future<AdditionalDetailsResultDTO> onAdditionalDetails(
    String checkoutId,
    ActionComponentDataDTO data,
  ) =>
      runtime._onAdditionalDetails(checkoutId, data);

  @override
  Future<ApplePayShippingMethodUpdateDTO> onApplePaySelectShippingMethod(
    String checkoutId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  ) =>
      runtime._onApplePaySelectShippingMethod(
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
      runtime._onApplePaySelectShippingContact(
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
      runtime._onApplePayChangeCouponCode(
        checkoutId,
        couponCode,
        currentSummaryItems,
      );

  @override
  Future<ApplePayAuthorizationResultDTO> onApplePayAuthorize(
    String checkoutId,
    ApplePayAuthorizedPaymentDTO payment,
  ) =>
      runtime._onApplePayAuthorize(checkoutId, payment);
}

class _ActionOnlyApi extends ActionOnlyFlutterApi {
  final CheckoutRuntime runtime;

  _ActionOnlyApi(this.runtime);

  @override
  Future<AdditionalDetailsResultDTO> onAdditionalDetails(
    String actionId,
    ActionComponentDataDTO data,
  ) =>
      runtime._onActionAdditionalDetails(actionId, data);
}
