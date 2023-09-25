import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_result_api.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';

class AdyenCheckout implements AdyenCheckoutInterface {
  AdyenCheckout() {
    _setupResultApi();
  }

  final AdyenCheckoutResultApi _resultApi = AdyenCheckoutResultApi();

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

  Future<PaymentResult> _startDropInSessionsPayment(
      DropInSession dropInSession) async {
    _resultApi.dropInSessionResultStream = StreamController<PaymentResultDTO>();

    DropInConfigurationDTO dropInConfiguration = DropInConfigurationDTO(
      environment: dropInSession.dropInConfiguration.environment,
      clientKey: dropInSession.dropInConfiguration.clientKey,
      countryCode: dropInSession.dropInConfiguration.countryCode,
      amount: dropInSession.dropInConfiguration.amount,
      shopperLocale: dropInSession.dropInConfiguration.shopperLocale,
      cardsConfigurationDTO:
          dropInSession.dropInConfiguration.cardsConfigurationDTO,
      applePayConfigurationDTO:
          dropInSession.dropInConfiguration.applePayConfigurationDTO,
      googlePayConfigurationDTO:
          dropInSession.dropInConfiguration.googlePayConfigurationDTO,
      cashAppPayConfigurationDTO:
          dropInSession.dropInConfiguration.cashAppPayConfigurationDTO,
      analyticsOptionsDTO:
          dropInSession.dropInConfiguration.analyticsOptionsDTO,
      //TODO - Remove disable flag for store payment field when native SDK receive updates.
      isRemoveStoredPaymentMethodEnabled: false,
      // isRemoveStoredPaymentMethodEnabled:
      //     dropInSession.dropInConfiguration.isRemoveStoredPaymentMethodEnabled,
      showPreselectedStoredPaymentMethod:
          dropInSession.dropInConfiguration.showPreselectedStoredPaymentMethod,
      skipListWhenSinglePaymentMethod:
          dropInSession.dropInConfiguration.skipListWhenSinglePaymentMethod,
    );

    AdyenCheckoutPlatformInterface.instance.startDropInSessionPayment(
      session: dropInSession.session.toDTO(),
      dropInConfiguration: dropInConfiguration,
    );

    final sessionDropInResultModel =
        await _resultApi.dropInSessionResultStream.stream.first;
    await _resultApi.dropInSessionResultStream.close();
    return sessionDropInResultModel.fromDTO();
  }

  Future<PaymentResult> _startDropInAdvancedFlowPayment(
      DropInAdvancedFlow dropInAdvancedFlow) async {
    final dropInAdvancedFlowCompleter = Completer<PaymentResultDTO>();
    DropInConfigurationDTO dropInConfiguration = DropInConfigurationDTO(
      environment: dropInAdvancedFlow.dropInConfiguration.environment,
      clientKey: dropInAdvancedFlow.dropInConfiguration.clientKey,
      countryCode: dropInAdvancedFlow.dropInConfiguration.countryCode,
      amount: dropInAdvancedFlow.dropInConfiguration.amount,
      shopperLocale: dropInAdvancedFlow.dropInConfiguration.shopperLocale,
      cardsConfigurationDTO:
          dropInAdvancedFlow.dropInConfiguration.cardsConfigurationDTO,
      applePayConfigurationDTO:
          dropInAdvancedFlow.dropInConfiguration.applePayConfigurationDTO,
      googlePayConfigurationDTO:
          dropInAdvancedFlow.dropInConfiguration.googlePayConfigurationDTO,
      cashAppPayConfigurationDTO:
          dropInAdvancedFlow.dropInConfiguration.cashAppPayConfigurationDTO,
      analyticsOptionsDTO:
          dropInAdvancedFlow.dropInConfiguration.analyticsOptionsDTO,
      showPreselectedStoredPaymentMethod: dropInAdvancedFlow.dropInConfiguration
          .storedPaymentMethodConfiguration?.showPreselectedStoredPaymentMethod,
      isRemoveStoredPaymentMethodEnabled: dropInAdvancedFlow.dropInConfiguration
          .storedPaymentMethodConfiguration?.isRemoveStoredPaymentMethodEnabled,
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
            dropInAdvancedFlow.dropInConfiguration,
          );
      }
    });

    return dropInAdvancedFlowCompleter.future.then((value) {
      _resultApi.dropInAdvancedFlowPlatformCommunicationStream.close();
      return value.fromDTO();
    });
  }

  void _handleResult(
    Completer<PaymentResultDTO> dropInAdvancedFlowCompleter,
    PlatformCommunicationModel event,
  ) {
    dropInAdvancedFlowCompleter.complete(event.paymentResult);
  }

  Future<void> _handleAdditionalDetails(
    PlatformCommunicationModel event,
    Future<DropInOutcome> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    if (event.data == null) {
      throw Exception("Additional data is not provided.");
    }

    final DropInOutcome paymentsDetailsResult =
        await postPaymentsDetails(event.data!);
    DropInResultDTO dropInResult = _mapToDropInResult(paymentsDetailsResult);
    AdyenCheckoutPlatformInterface.instance
        .onPaymentsDetailsResult(dropInResult);
  }

  Future<void> _handlePaymentComponent(
    PlatformCommunicationModel event,
    Future<DropInOutcome> Function(String paymentComponentJson) postPayments,
  ) async {
    if (event.data == null) {
      throw Exception("Payment data is not provided.");
    }

    final DropInOutcome paymentsResult = await postPayments(event.data!);
    DropInResultDTO dropInResult = _mapToDropInResult(paymentsResult);
    AdyenCheckoutPlatformInterface.instance.onPaymentsResult(dropInResult);
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
    DropInConfiguration dropInConfiguration,
  ) async {
    if (dropInConfiguration.storedPaymentMethodConfiguration
            ?.deleteStoredPaymentMethodCallback ==
        null) {
      return;
    } else {
      final storedPaymentMethodId = event.data;
      final result = await dropInConfiguration.storedPaymentMethodConfiguration
              ?.deleteStoredPaymentMethodCallback!(storedPaymentMethodId!) ??
          false;
      AdyenCheckoutPlatformInterface.instance.onDeleteStoredPaymentMethodResult(
          DeletedStoredPaymentMethodResultDTO(
        storedPaymentMethodId: storedPaymentMethodId!,
        isSuccessfullyRemoved: result,
      ));
    }
  }
}
