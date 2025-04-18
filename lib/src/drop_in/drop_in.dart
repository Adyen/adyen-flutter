import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_flutter.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';

class DropIn {
  DropIn(
    this.sdkVersionNumberProvider,
    this.dropInFlutter,
    this.dropInPlatformApi,
  ) {
    CheckoutFlutterInterface.setUp(dropInFlutter);
  }

  final PaymentEventHandler _paymentEventHandler = PaymentEventHandler();
  final AdyenLogger adyenLogger = AdyenLogger.instance;
  final SdkVersionNumberProvider sdkVersionNumberProvider;
  final DropInFlutter dropInFlutter;
  final DropInPlatformApi dropInPlatformApi;

  Future<PaymentResult> startDropInSessionsPayment(
    DropInConfiguration dropInConfiguration,
    SessionCheckout sessionCheckout,
  ) async {
    adyenLogger.print("Start Drop-in session");
    final dropInSessionCompleter = Completer<PaymentResultDTO>();
    final sdkVersionNumber =
        await sdkVersionNumberProvider.getSdkVersionNumber();

    dropInPlatformApi.showDropInSession(
      dropInConfiguration.toDTO(sdkVersionNumber, true),
    );

    dropInFlutter.platformEventStream = StreamController<CheckoutEvent>();
    final platformEventSubscription =
        dropInFlutter.platformEventStream?.stream.listen((event) async {
      switch (event.type) {
        case CheckoutEventType.result:
          _handleResult(
            event,
            dropInSessionCompleter,
          );
        case CheckoutEventType.deleteStoredPaymentMethod:
          _handleDeleteStoredPaymentMethod(
            event,
            dropInConfiguration.storedPaymentMethodConfiguration,
          );
        case CheckoutEventType.binLookup:
          _handleBinLookup(
            event,
            dropInConfiguration.cardConfiguration?.onBinLookup,
          );
        case CheckoutEventType.binValue:
          _handleBinValue(
            event,
            dropInConfiguration.cardConfiguration?.onBinValue,
          );
        default:
      }
    });

    return dropInSessionCompleter.future.then((paymentResultDTO) async {
      await platformEventSubscription?.cancel();
      await _cleanUpDropIn();
      adyenLogger
          .print("Drop-in session result type: ${paymentResultDTO.type.name}");
      adyenLogger.print(
          "Drop-in session result code: ${paymentResultDTO.result?.resultCode}");
      return switch (paymentResultDTO.type) {
        PaymentResultEnum.cancelledByUser => PaymentCancelledByUser(),
        PaymentResultEnum.error =>
          PaymentError(reason: paymentResultDTO.reason),
        PaymentResultEnum.finished => PaymentSessionFinished(
            sessionId: paymentResultDTO.result?.sessionId ?? "",
            sessionData: paymentResultDTO.result?.sessionData ?? "",
            sessionResult: paymentResultDTO.result?.sessionResult ?? "",
            resultCode:
                paymentResultDTO.result?.toResultCode() ?? ResultCode.unknown,
            order: paymentResultDTO.result?.order?.fromDTO(),
          )
      };
    });
  }

  Future<PaymentResult> startDropInAdvancedFlowPayment(
    DropInConfiguration dropInConfiguration,
    Map<String, dynamic> paymentMethodsResponse,
    AdvancedCheckout advancedCheckout,
  ) async {
    adyenLogger.print("Start Drop-in advanced flow");
    final dropInAdvancedFlowCompleter = Completer<PaymentResultDTO>();
    final sdkVersionNumber =
        await sdkVersionNumberProvider.getSdkVersionNumber();
    final encodedPaymentMethodsResponse = jsonEncode(
      paymentMethodsResponse,
      toEncodable: (value) => throw Exception("Could not encode $value"),
    );
    final isPartialPaymentSupported = advancedCheckout.partialPayment != null;

    dropInPlatformApi.showDropInAdvanced(
      dropInConfiguration.toDTO(
        sdkVersionNumber,
        isPartialPaymentSupported,
      ),
      encodedPaymentMethodsResponse,
    );

    dropInFlutter.platformEventStream = StreamController<CheckoutEvent>();
    final platformEventSubscription =
        dropInFlutter.platformEventStream?.stream.listen((event) async {
      switch (event.type) {
        case CheckoutEventType.submit:
          await _handleSubmit(
            event,
            advancedCheckout,
          );
        case CheckoutEventType.additionalDetails:
          await _handleAdditionalDetails(
            event,
            advancedCheckout,
          );
        case CheckoutEventType.result:
          _handleResult(
            event,
            dropInAdvancedFlowCompleter,
          );
        case CheckoutEventType.deleteStoredPaymentMethod:
          _handleDeleteStoredPaymentMethod(
            event,
            dropInConfiguration.storedPaymentMethodConfiguration,
          );
        case CheckoutEventType.balanceCheck:
          _handleCheckBalance(
            event,
            advancedCheckout.partialPayment?.onCheckBalance,
          );
        case CheckoutEventType.requestOrder:
          _handleOrderRequest(
            event,
            advancedCheckout.partialPayment?.onRequestOrder,
          );
        case CheckoutEventType.cancelOrder:
          _handleOrderCancel(
            event,
            advancedCheckout.partialPayment?.onCancelOrder,
          );
        case CheckoutEventType.binLookup:
          _handleBinLookup(
            event,
            dropInConfiguration.cardConfiguration?.onBinLookup,
          );
        case CheckoutEventType.binValue:
          _handleBinValue(
            event,
            dropInConfiguration.cardConfiguration?.onBinValue,
          );
      }
    });

    return dropInAdvancedFlowCompleter.future.then((paymentResultDTO) async {
      await platformEventSubscription?.cancel();
      await _cleanUpDropIn();
      adyenLogger.print(
          "Drop-in advanced flow result type: ${paymentResultDTO.type.name}");
      adyenLogger.print(
          "Drop-in advanced flow result code: ${paymentResultDTO.result?.resultCode}");
      return switch (paymentResultDTO.type) {
        PaymentResultEnum.cancelledByUser => PaymentCancelledByUser(),
        PaymentResultEnum.error =>
          PaymentError(reason: paymentResultDTO.reason),
        PaymentResultEnum.finished => PaymentAdvancedFinished(
            resultCode:
                paymentResultDTO.result?.toResultCode() ?? ResultCode.unknown)
      };
    });
  }

  Future<void> stopDropIn() async => await dropInPlatformApi.stopDropIn();

  Future<void> _cleanUpDropIn() async {
    dropInPlatformApi.cleanUpDropIn();
    await dropInFlutter.platformEventStream?.close();
    dropInFlutter.platformEventStream = null;
  }

  void _handleResult(
    CheckoutEvent event,
    Completer<PaymentResultDTO> completer,
  ) {
    switch (event.data) {
      case PaymentResultDTO paymentResultDTO:
        completer.complete(paymentResultDTO);
      default:
        completer.complete(PaymentResultDTO(
          type: PaymentResultEnum.error,
          reason: "Missing payment result data",
        ));
    }
  }

  Future<void> _handleSubmit(
    CheckoutEvent event,
    Checkout advancedCheckout,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Payment data is not provided.");
      }

      final PaymentEvent paymentEvent =
          await _getOnSubmitPaymentEvent(event, advancedCheckout);
      PaymentEventDTO paymentEventDTO =
          _paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      dropInPlatformApi.onPaymentsResult(paymentEventDTO);
    } catch (error) {
      String errorMessage = error.toString();
      adyenLogger.print("Failure in onSubmit, $errorMessage");
      dropInPlatformApi.onPaymentsResult(PaymentEventDTO(
        paymentEventType: PaymentEventType.error,
        error: ErrorDTO(
          errorMessage: errorMessage,
          reason: "Failure in onSubmit, $errorMessage",
          dismissDropIn: false,
        ),
      ));
    }
  }

  Future<void> _handleAdditionalDetails(
    CheckoutEvent event,
    Checkout advancedCheckout,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Additional data is not provided.");
      }

      final PaymentEvent paymentEvent =
          await _getOnAdditionalDetailsPaymentEvent(event, advancedCheckout);
      PaymentEventDTO paymentEventDTO =
          _paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      dropInPlatformApi.onPaymentsDetailsResult(paymentEventDTO);
    } catch (error) {
      String errorMessage = error.toString();
      adyenLogger.print("Failure in onAdditionalDetails, $errorMessage");
      dropInPlatformApi.onPaymentsDetailsResult(PaymentEventDTO(
        paymentEventType: PaymentEventType.error,
        error: ErrorDTO(
          errorMessage: errorMessage,
          reason: "Failure in onAdditionalDetails, $errorMessage}",
          dismissDropIn: false,
        ),
      ));
    }
  }

  Future<void> _handleDeleteStoredPaymentMethod(
    CheckoutEvent event,
    StoredPaymentMethodConfiguration? storedPaymentMethodConfiguration,
  ) async {
    final deletionCallback =
        storedPaymentMethodConfiguration?.deleteStoredPaymentMethodCallback;

    if (deletionCallback != null) {
      try {
        final String storedPaymentMethodId = event.data as String;
        final bool result = await deletionCallback(storedPaymentMethodId);
        dropInPlatformApi.onDeleteStoredPaymentMethodResult(
            DeletedStoredPaymentMethodResultDTO(
          storedPaymentMethodId: storedPaymentMethodId,
          isSuccessfullyRemoved: result,
        ));
      } catch (error) {
        adyenLogger.print(error.toString());
        dropInPlatformApi.onDeleteStoredPaymentMethodResult(
            DeletedStoredPaymentMethodResultDTO(
          storedPaymentMethodId: "",
          isSuccessfullyRemoved: false,
        ));
      }
    }
  }

  Future<PaymentEvent> _getOnSubmitPaymentEvent(
    CheckoutEvent event,
    Checkout advancedCheckout,
  ) async {
    final String submitData = (event.data as String);
    final Map<String, dynamic> submitDataDecoded = jsonDecode(submitData);
    switch (advancedCheckout) {
      case AdvancedCheckout it:
        if (submitDataDecoded[Constants.submitDataKey]
            .containsKey(Constants.orderKey)) {
          _mapOrderToCompactOrder(submitDataDecoded);
        }

        final PaymentEvent paymentEvent = await it.onSubmit(
          submitDataDecoded[Constants.submitDataKey],
          submitDataDecoded[Constants.submitExtraKey],
        );
        return paymentEvent;
      case SessionCheckout():
        throw Exception("Please use the session card component.");
    }
  }

  // iOS provides more fields than needed. Therefore, only the necessary fields are used.
  void _mapOrderToCompactOrder(Map<String, dynamic> submitDataDecoded) {
    final order =
        submitDataDecoded[Constants.submitDataKey][Constants.orderKey];
    submitDataDecoded[Constants.submitDataKey][Constants.orderKey] = {
      Constants.pspReferenceKey: order[Constants.pspReferenceKey],
      Constants.orderDataKey: order[Constants.orderDataKey],
    };
  }

  Future<PaymentEvent> _getOnAdditionalDetailsPaymentEvent(
    CheckoutEvent event,
    Checkout advancedCheckout,
  ) async {
    switch (advancedCheckout) {
      case AdvancedCheckout it:
        final additionalDetails = jsonDecode(event.data as String);
        return await it.onAdditionalDetails(additionalDetails);
      case SessionCheckout():
        throw Exception("Please use the session card component.");
    }
  }

  void _handleCheckBalance(
    CheckoutEvent event,
    Future<Map<String, dynamic>> Function({
      required Map<String, dynamic> balanceCheckRequestBody,
    })? onCheckBalance,
  ) async {
    try {
      if (onCheckBalance == null) {
        return;
      }

      final data = jsonDecode(event.data as String);
      final Map<String, dynamic> balanceCheckRequestBody = {
        Constants.paymentMethodKey: data[Constants.paymentMethodKey],
        Constants.amountKey: data[Constants.amountKey],
      };
      final balanceCheckResponse = await onCheckBalance(
          balanceCheckRequestBody: balanceCheckRequestBody);
      dropInPlatformApi.onBalanceCheckResult(jsonEncode(balanceCheckResponse));
    } catch (error) {
      dropInPlatformApi.onBalanceCheckResult(error.toString());
    }
  }

  void _handleOrderRequest(
    CheckoutEvent event,
    Future<Map<String, dynamic>> Function()? onRequestOrder,
  ) async {
    try {
      if (onRequestOrder == null) {
        return;
      }

      final orderRequestResponse = await onRequestOrder();
      dropInPlatformApi.onOrderRequestResult(jsonEncode(orderRequestResponse));
    } catch (error) {
      dropInPlatformApi.onOrderRequestResult(error.toString());
    }
  }

  void _handleOrderCancel(
    CheckoutEvent event,
    Future<OrderCancelResult> Function({
      required Map<String, dynamic> order,
      required bool shouldUpdatePaymentMethods,
    })? onCancelOrder,
  ) async {
    try {
      if (onCancelOrder == null) {
        return;
      }

      final orderResponse = jsonDecode(event.data as String);
      final orderCancelResponse = await onCancelOrder(
        shouldUpdatePaymentMethods:
            orderResponse[Constants.shouldUpdatePaymentMethodsKey] as bool? ??
                false,
        order: orderResponse[Constants.orderKey],
      );
      final orderCancelResponseDTO = orderCancelResponse.toDTO();
      dropInPlatformApi.onOrderCancelResult(orderCancelResponseDTO);
    } catch (error) {
      dropInPlatformApi.onOrderCancelResult(
          OrderCancelResultDTO(orderCancelResponseBody: {}));
    }
  }

  void _handleBinLookup(
    CheckoutEvent event,
    void Function(List<BinLookupData> binLookupData)? onBinLookup,
  ) {
    if (onBinLookup == null) {
      return;
    }

    if (event.data case List<Object?> binLookupDataDTOList) {
      onBinLookup.call(binLookupDataDTOList
          .whereType<BinLookupDataDTO>()
          .toBinLookupDataList());
    }
  }

  void _handleBinValue(
    CheckoutEvent event,
    void Function(String binValue)? onBinValue,
  ) {
    if (onBinValue == null) {
      return;
    }

    if (event.data case String binValue) {
      onBinValue.call(binValue);
    }
  }
}
