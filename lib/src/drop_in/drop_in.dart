import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_flutter_api.dart';
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
    this.dropInFlutterApi,
    this.dropInPlatformApi,
  ) {
    DropInFlutterInterface.setup(dropInFlutterApi);
  }

  final PaymentEventHandler _paymentEventHandler = PaymentEventHandler();
  final AdyenLogger adyenLogger = AdyenLogger.instance;
  final SdkVersionNumberProvider sdkVersionNumberProvider;
  final DropInFlutterApi dropInFlutterApi;
  final DropInPlatformApi dropInPlatformApi;

  Future<PaymentResult> startDropInSessionsPayment(
    DropInConfiguration dropInConfiguration,
    SessionCheckout dropInSession,
  ) async {
    adyenLogger.print("Start Drop-in session");
    final dropInSessionCompleter = Completer<PaymentResultDTO>();
    final sdkVersionNumber =
        await sdkVersionNumberProvider.getSdkVersionNumber();

    dropInPlatformApi.showDropInSession(
      dropInConfiguration.toDTO(sdkVersionNumber, true),
    );

    dropInFlutterApi.dropInSessionPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    dropInFlutterApi.dropInSessionPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.result:
          dropInSessionCompleter.complete(event.paymentResult);
        case PlatformCommunicationType.deleteStoredPaymentMethod:
          _onDeleteStoredPaymentMethodCallback(
            event,
            dropInConfiguration.storedPaymentMethodConfiguration,
          );
        default:
      }
    });

    return dropInSessionCompleter.future.then((paymentResultDTO) {
      dropInPlatformApi.cleanUpDropIn();
      dropInFlutterApi.dropInSessionPlatformCommunicationStream.close();
      adyenLogger
          .print("Drop-in session result type: ${paymentResultDTO.type.name}");
      adyenLogger.print(
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
            sessionResult: paymentResultDTO.result?.sessionResult ?? "",
            resultCode:
                paymentResultDTO.result?.toResultCode() ?? ResultCode.unknown,
            order: paymentResultDTO.result?.order?.fromDTO(),
          );
      }
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

    dropInFlutterApi.dropInAdvancedFlowPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    dropInFlutterApi.dropInAdvancedFlowPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.paymentComponent:
          await _handlePaymentComponent(event, advancedCheckout);
        case PlatformCommunicationType.additionalDetails:
          await _handleAdditionalDetails(event, advancedCheckout);
        case PlatformCommunicationType.result:
          _handleResult(dropInAdvancedFlowCompleter, event);
        case PlatformCommunicationType.deleteStoredPaymentMethod:
          _onDeleteStoredPaymentMethodCallback(
            event,
            dropInConfiguration.storedPaymentMethodConfiguration,
          );
        case PlatformCommunicationType.balanceCheck:
          _handleBalanceCheck(event, advancedCheckout.partialPayment);
        case PlatformCommunicationType.requestOrder:
          _handleOrderRequest(event, advancedCheckout.partialPayment);
        case PlatformCommunicationType.cancelOrder:
          _handleOrderCancel(event, advancedCheckout.partialPayment);
      }
    });

    return dropInAdvancedFlowCompleter.future.then((paymentResultDTO) {
      dropInPlatformApi.cleanUpDropIn();
      dropInFlutterApi.dropInAdvancedFlowPlatformCommunicationStream.close();
      adyenLogger.print(
          "Drop-in advanced flow result type: ${paymentResultDTO.type.name}");
      adyenLogger.print(
          "Drop-in advanced flow result code: ${paymentResultDTO.result?.resultCode}");
      switch (paymentResultDTO.type) {
        case PaymentResultEnum.cancelledByUser:
          return PaymentCancelledByUser();
        case PaymentResultEnum.error:
          return PaymentError(reason: paymentResultDTO.reason);
        case PaymentResultEnum.finished:
          return PaymentAdvancedFinished(
              resultCode: paymentResultDTO.result?.toResultCode() ??
                  ResultCode.unknown);
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
    PlatformCommunicationModel event,
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
        dropInPlatformApi.onDeleteStoredPaymentMethodResult(
            DeletedStoredPaymentMethodResultDTO(
          storedPaymentMethodId: storedPaymentMethodId,
          isSuccessfullyRemoved: result,
        ));
      } catch (error) {
        adyenLogger.print(error.toString());
        dropInPlatformApi.onDeleteStoredPaymentMethodResult(
            DeletedStoredPaymentMethodResultDTO(
          storedPaymentMethodId: storedPaymentMethodId,
          isSuccessfullyRemoved: false,
        ));
      }
    }
  }

  Future<PaymentEvent> _getOnSubmitPaymentEvent(
      PlatformCommunicationModel event, Checkout advancedCheckout) async {
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
      PlatformCommunicationModel event, Checkout advancedCheckout) async {
    switch (advancedCheckout) {
      case AdvancedCheckout it:
        final additionalDetails = jsonDecode(event.data as String);
        return await it.onAdditionalDetails(additionalDetails);
      case SessionCheckout():
        throw Exception("Please use the session card component.");
    }
  }

  void _handleBalanceCheck(
    PlatformCommunicationModel event,
    PartialPayment? partialPayment,
  ) async {
    try {
      final data = jsonDecode(event.data as String);
      final Map<String, dynamic> balanceCheckRequestBody = {
        Constants.paymentMethodKey: data[Constants.paymentMethodKey],
        Constants.amountKey: data[Constants.amountKey],
      };
      final balanceCheckResponse = await partialPayment?.onCheckBalance(
          balanceCheckRequestBody: balanceCheckRequestBody);
      dropInPlatformApi.onBalanceCheckResult(jsonEncode(balanceCheckResponse));
    } catch (error) {
      dropInPlatformApi.onBalanceCheckResult(error.toString());
    }
  }

  void _handleOrderRequest(
    PlatformCommunicationModel event,
    PartialPayment? partialPayment,
  ) async {
    try {
      final orderRequestResponse = await partialPayment?.onRequestOrder();
      dropInPlatformApi.onOrderRequestResult(jsonEncode(orderRequestResponse));
    } catch (error) {
      dropInPlatformApi.onOrderRequestResult(error.toString());
    }
  }

  void _handleOrderCancel(
    PlatformCommunicationModel event,
    PartialPayment? partialPayment,
  ) async {
    try {
      final orderResponse = jsonDecode(event.data as String);
      final orderCancelResponse = await partialPayment?.onCancelOrder(
        shouldUpdatePaymentMethods:
            orderResponse[Constants.shouldUpdatePaymentMethodsKey] as bool? ??
                false,
        order: orderResponse[Constants.orderKey],
      );
      final orderCancelResponseDTO = orderCancelResponse?.toDTO() ??
          OrderCancelResultDTO(orderCancelResponseBody: {});
      dropInPlatformApi.onOrderCancelResult(orderCancelResponseDTO);
    } catch (error) {
      dropInPlatformApi.onOrderCancelResult(
          OrderCancelResultDTO(orderCancelResponseBody: {}));
    }
  }
}
