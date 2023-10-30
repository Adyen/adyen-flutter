import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_result_api.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:flutter/foundation.dart';

class AdyenCheckout implements AdyenCheckoutInterface {
  AdyenCheckout() {
    _setupResultApi();
  }

  final AdyenCheckoutResultApi _resultApi = AdyenCheckoutResultApi();
  final AdyenLogger _adyenLogger = AdyenLogger();

  @override
  Future<String> getPlatformVersion() =>
      AdyenCheckoutPlatformInterface.instance.getPlatformVersion();

  @override
  Future<String> getReturnUrl() =>
      AdyenCheckoutPlatformInterface.instance.getReturnUrl();

  @override
  Future<PaymentResult> startPayment({required PaymentFlow paymentFlow}) async {
    switch (paymentFlow) {
      case DropInSession():
        return await _startDropInSessionsPayment(paymentFlow);
      case DropInAdvancedFlow():
        return await _startDropInAdvancedFlowPayment(paymentFlow);
    }
  }

  @override
  void enableLogging({required bool loggingEnabled}) {
    if (kDebugMode) {
      _adyenLogger.enableLogging(loggingEnabled: loggingEnabled);
      AdyenCheckoutPlatformInterface.instance.enableLogging(loggingEnabled);
    }
  }

  Future<PaymentResult> _startDropInSessionsPayment(
      DropInSession dropInSession) async {
    _adyenLogger.print("Start Drop-in session");
    final dropInSessionCompleter = Completer<PaymentResultDTO>();
    AdyenCheckoutPlatformInterface.instance.startDropInSessionPayment(
      session: dropInSession.session.toDTO(),
      dropInConfiguration: dropInSession.dropInConfiguration.toDTO(),
    );

    _resultApi.dropInSessionPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    _resultApi.dropInSessionPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.result:
          dropInSessionCompleter.complete(event.paymentResult);
        case PlatformCommunicationType.deleteStoredPaymentMethod:
          _onDeleteStoredPaymentMethodCallback(
            event,
            dropInSession.dropInConfiguration.storedPaymentMethodConfiguration,
          );
        default:
      }
    });

    return dropInSessionCompleter.future.then((paymentResultDTO) {
      AdyenCheckoutPlatformInterface.instance.cleanUpDropIn();
      _resultApi.dropInSessionPlatformCommunicationStream.close();
      _adyenLogger
          .print("Drop-in session result type: ${paymentResultDTO.type.name}");
      _adyenLogger.print(
          "Drop-in session result code: ${paymentResultDTO.result?.resultCode}");
      switch (paymentResultDTO.type) {
        case PaymentResultEnum.cancelledByUser:
          return PaymentCancelledByUser();
        case PaymentResultEnum.error:
          return PaymentError(reason: paymentResultDTO.reason);
        case PaymentResultEnum.finished:
          return PaymentSessionFinished(
            sessionId: paymentResultDTO.result?.sessionId ?? "",
            sessionData: paymentResultDTO.result?.sessionData ?? "",
            resultCode: paymentResultDTO.result?.resultCode ?? "",
            order: paymentResultDTO.result?.order?.fromDTO(),
          );
      }
    });
  }

  Future<PaymentResult> _startDropInAdvancedFlowPayment(
      DropInAdvancedFlow dropInAdvancedFlow) async {
    _adyenLogger.print("Start Drop-in advanced flow");
    final dropInAdvancedFlowCompleter = Completer<PaymentResultDTO>();

    AdyenCheckoutPlatformInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse: dropInAdvancedFlow.paymentMethodsResponse,
      dropInConfiguration: dropInAdvancedFlow.dropInConfiguration.toDTO(),
    );

    _resultApi.dropInAdvancedFlowPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    _resultApi.dropInAdvancedFlowPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.paymentComponent:
          await _handlePaymentComponent(event, dropInAdvancedFlow.postPayments);
        case PlatformCommunicationType.additionalDetails:
          await _handleAdditionalDetails(
              event, dropInAdvancedFlow.postPaymentsDetails);
        case PlatformCommunicationType.result:
          _handleResult(dropInAdvancedFlowCompleter, event);
        case PlatformCommunicationType.deleteStoredPaymentMethod:
          _onDeleteStoredPaymentMethodCallback(
            event,
            dropInAdvancedFlow
                .dropInConfiguration.storedPaymentMethodConfiguration,
          );
      }
    });

    return dropInAdvancedFlowCompleter.future.then((paymentResultDTO) {
      AdyenCheckoutPlatformInterface.instance.cleanUpDropIn();
      _resultApi.dropInAdvancedFlowPlatformCommunicationStream.close();
      _adyenLogger.print(
          "Drop-in advanced flow result type: ${paymentResultDTO.type.name}");
      _adyenLogger.print(
          "Drop-in advanced flow result code: ${paymentResultDTO.result?.resultCode}");
      switch (paymentResultDTO.type) {
        case PaymentResultEnum.cancelledByUser:
          return PaymentCancelledByUser();
        case PaymentResultEnum.error:
          return PaymentError(reason: paymentResultDTO.reason);
        case PaymentResultEnum.finished:
          return PaymentAdvancedFlowFinished(
            resultCode: paymentResultDTO.result?.resultCode ?? "",
          );
      }
    });
  }

  void _handleResult(
    Completer<PaymentResultDTO> dropInAdvancedFlowCompleter,
    PlatformCommunicationModel event,
  ) {
    dropInAdvancedFlowCompleter.complete(event.paymentResult);
  }

  Future<void> _handlePaymentComponent(
    PlatformCommunicationModel event,
    Future<PaymentFlowOutcome> Function(String paymentComponentJson)
        postPayments,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Payment data is not provided.");
      }

      final PaymentFlowOutcome paymentFlowOutcome = await postPayments(event.data!);
      DropInResultDTO dropInResult = _mapToDropInResult(paymentFlowOutcome);
      AdyenCheckoutPlatformInterface.instance.onPaymentsResult(dropInResult);
    } catch (error) {
      String errorMessage = error.toString();
      _adyenLogger.print("Failure in postPayments, $errorMessage");
      AdyenCheckoutPlatformInterface.instance.onPaymentsResult(DropInResultDTO(
        dropInResultType: DropInResultType.error,
        error: DropInErrorDTO(
          errorMessage: errorMessage,
          reason: "Failure in postPayments, $errorMessage",
          dismissDropIn: false,
        ),
      ));
    }
  }

  Future<void> _handleAdditionalDetails(
    PlatformCommunicationModel event,
    Future<PaymentFlowOutcome> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Additional data is not provided.");
      }

      final PaymentFlowOutcome paymentFlowOutcome = await postPaymentsDetails(event.data!);
      DropInResultDTO dropInResult = _mapToDropInResult(paymentFlowOutcome);
      AdyenCheckoutPlatformInterface.instance
          .onPaymentsDetailsResult(dropInResult);
    } catch (error) {
      String errorMessage = error.toString();
      _adyenLogger.print("Failure in postPaymentsDetails, $errorMessage");
      AdyenCheckoutPlatformInterface.instance
          .onPaymentsDetailsResult(DropInResultDTO(
        dropInResultType: DropInResultType.error,
        error: DropInErrorDTO(
          errorMessage: errorMessage,
          reason: "Failure in postPaymentsDetails, $errorMessage}",
          dismissDropIn: false,
        ),
      ));
    }
  }

  DropInResultDTO _mapToDropInResult(PaymentFlowOutcome dropInOutcome) {
    return switch (dropInOutcome) {
      Finished() => DropInResultDTO(
          dropInResultType: DropInResultType.finished,
          result: dropInOutcome.resultCode,
        ),
      Action() => DropInResultDTO(
          dropInResultType: DropInResultType.action,
          actionResponse: dropInOutcome.actionResponse,
        ),
      Error() => DropInResultDTO(
          dropInResultType: DropInResultType.error,
          error: DropInErrorDTO(
            errorMessage: dropInOutcome.errorMessage,
            reason: dropInOutcome.reason,
            dismissDropIn: dropInOutcome.dismissDropIn,
          ),
        ),
    };
  }

  void _setupResultApi() => CheckoutFlutterApi.setup(_resultApi);

  Future<void> _onDeleteStoredPaymentMethodCallback(
    PlatformCommunicationModel event,
    StoredPaymentMethodConfiguration? storedPaymentMethodConfiguration,
  ) async {
    final String? storedPaymentMethodId = event.data;
    final deletionCallback =
        storedPaymentMethodConfiguration?.deleteStoredPaymentMethodCallback;

    if (storedPaymentMethodId != null && deletionCallback != null) {
      try {
        final bool result = await deletionCallback(storedPaymentMethodId);
        AdyenCheckoutPlatformInterface.instance
            .onDeleteStoredPaymentMethodResult(
                DeletedStoredPaymentMethodResultDTO(
          storedPaymentMethodId: storedPaymentMethodId,
          isSuccessfullyRemoved: result,
        ));
      } catch (error) {
        _adyenLogger.print(error.toString());
        AdyenCheckoutPlatformInterface.instance
            .onDeleteStoredPaymentMethodResult(
                DeletedStoredPaymentMethodResultDTO(
          storedPaymentMethodId: storedPaymentMethodId,
          isSuccessfullyRemoved: false,
        ));
      }
    }
  }

  bool isRemoveStoredPaymentMethodEnabled(
      DropInConfiguration dropInConfiguration) {
    return dropInConfiguration.storedPaymentMethodConfiguration
                ?.deleteStoredPaymentMethodCallback !=
            null &&
        dropInConfiguration.storedPaymentMethodConfiguration
                ?.isRemoveStoredPaymentMethodEnabled ==
            true;
  }
}
