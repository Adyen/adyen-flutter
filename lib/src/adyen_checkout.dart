import 'dart:async';
import 'dart:io';

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
    DropInConfigurationDTO dropInConfiguration = DropInConfigurationDTO(
      environment: dropInSession.dropInConfiguration.environment,
      clientKey: dropInSession.dropInConfiguration.clientKey,
      countryCode: dropInSession.dropInConfiguration.countryCode,
      amount: dropInSession.dropInConfiguration.amount.toDTO(),
      shopperLocale: dropInSession.dropInConfiguration.shopperLocale ??
          Platform.localeName,
      cardsConfigurationDTO:
          dropInSession.dropInConfiguration.cardsConfiguration?.toDTO(),
      applePayConfigurationDTO:
          dropInSession.dropInConfiguration.applePayConfiguration?.toDTO(),
      googlePayConfigurationDTO:
          dropInSession.dropInConfiguration.googlePayConfiguration?.toDTO(),
      cashAppPayConfigurationDTO:
          dropInSession.dropInConfiguration.cashAppPayConfiguration?.toDTO(),
      analyticsOptionsDTO:
          dropInSession.dropInConfiguration.analyticsOptions?.toDTO(),
      isRemoveStoredPaymentMethodEnabled:
          isRemoveStoredPaymentMethodEnabled(dropInSession.dropInConfiguration),
      showPreselectedStoredPaymentMethod: dropInSession
              .dropInConfiguration
              .storedPaymentMethodConfiguration
              ?.showPreselectedStoredPaymentMethod ??
          true,
      skipListWhenSinglePaymentMethod:
          dropInSession.dropInConfiguration.skipListWhenSinglePaymentMethod,
    );
    AdyenCheckoutPlatformInterface.instance.startDropInSessionPayment(
      session: dropInSession.session.toDTO(),
      dropInConfiguration: dropInConfiguration,
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

    return dropInSessionCompleter.future.then((value) {
      AdyenCheckoutPlatformInterface.instance.cleanUpDropIn();
      _resultApi.dropInSessionPlatformCommunicationStream.close();
      _adyenLogger.print("Drop-in session result type: ${value.type.name}");
      _adyenLogger
          .print("Drop-in session result code: ${value.result?.resultCode}");
      return value.fromDTO();
    });
  }

  Future<PaymentResult> _startDropInAdvancedFlowPayment(
      DropInAdvancedFlow dropInAdvancedFlow) async {
    _adyenLogger.print("Start Drop-in advanced flow");
    final dropInAdvancedFlowCompleter = Completer<PaymentResultDTO>();
    DropInConfigurationDTO dropInConfiguration = DropInConfigurationDTO(
      environment: dropInAdvancedFlow.dropInConfiguration.environment,
      clientKey: dropInAdvancedFlow.dropInConfiguration.clientKey,
      countryCode: dropInAdvancedFlow.dropInConfiguration.countryCode,
      amount: dropInAdvancedFlow.dropInConfiguration.amount.toDTO(),
      shopperLocale: dropInAdvancedFlow.dropInConfiguration.shopperLocale ??
          Platform.localeName,
      cardsConfigurationDTO:
          dropInAdvancedFlow.dropInConfiguration.cardsConfiguration?.toDTO(),
      applePayConfigurationDTO:
          dropInAdvancedFlow.dropInConfiguration.applePayConfiguration?.toDTO(),
      googlePayConfigurationDTO: dropInAdvancedFlow
          .dropInConfiguration.googlePayConfiguration
          ?.toDTO(),
      cashAppPayConfigurationDTO: dropInAdvancedFlow
          .dropInConfiguration.cashAppPayConfiguration
          ?.toDTO(),
      analyticsOptionsDTO:
          dropInAdvancedFlow.dropInConfiguration.analyticsOptions?.toDTO(),
      showPreselectedStoredPaymentMethod: dropInAdvancedFlow
              .dropInConfiguration
              .storedPaymentMethodConfiguration
              ?.showPreselectedStoredPaymentMethod ??
          true,
      isRemoveStoredPaymentMethodEnabled: isRemoveStoredPaymentMethodEnabled(
          dropInAdvancedFlow.dropInConfiguration),
      skipListWhenSinglePaymentMethod: dropInAdvancedFlow
          .dropInConfiguration.skipListWhenSinglePaymentMethod,
    );

    AdyenCheckoutPlatformInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse: dropInAdvancedFlow.paymentMethodsResponse,
      dropInConfiguration: dropInConfiguration,
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

    return dropInAdvancedFlowCompleter.future.then((value) {
      AdyenCheckoutPlatformInterface.instance.cleanUpDropIn();
      _resultApi.dropInAdvancedFlowPlatformCommunicationStream.close();
      _adyenLogger
          .print("Drop-in advanced flow result type: ${value.type.name}");
      _adyenLogger.print(
          "Drop-in advanced flow result code: ${value.result?.resultCode}");
      return value.fromDTO();
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
    Future<DropInOutcome> Function(String paymentComponentJson) postPayments,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Payment data is not provided.");
      }

      final DropInOutcome paymentsResult = await postPayments(event.data!);
      DropInResultDTO dropInResult = _mapToDropInResult(paymentsResult);
      AdyenCheckoutPlatformInterface.instance.onPaymentsResult(dropInResult);
    } catch (error) {
      _adyenLogger.print(error.toString());
      AdyenCheckoutPlatformInterface.instance.onPaymentsResult(DropInResultDTO(
        dropInResultType: DropInResultType.error,
        error: DropInErrorDTO(
          reason: "Failure executing postPayments, ${error.toString()}",
          dismissDropIn: true,
        ),
      ));
    }
  }

  Future<void> _handleAdditionalDetails(
    PlatformCommunicationModel event,
    Future<DropInOutcome> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Additional data is not provided.");
      }

      final DropInOutcome paymentsDetailsResult =
          await postPaymentsDetails(event.data!);
      DropInResultDTO dropInResult = _mapToDropInResult(paymentsDetailsResult);
      AdyenCheckoutPlatformInterface.instance
          .onPaymentsDetailsResult(dropInResult);
    } catch (error) {
      _adyenLogger.print(error.toString());
      AdyenCheckoutPlatformInterface.instance
          .onPaymentsDetailsResult(DropInResultDTO(
        dropInResultType: DropInResultType.error,
        error: DropInErrorDTO(
          reason: "Failure executing postPaymentsDetails, ${error.toString()}",
          dismissDropIn: true,
        ),
      ));
    }
  }

  DropInResultDTO _mapToDropInResult(DropInOutcome dropInOutcome) {
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
