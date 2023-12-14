import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_flutter_api.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:adyen_checkout/src/utils/payment_outcome_handler.dart';
import 'package:adyen_checkout/src/utils/sdk_version_number_provider.dart';

class DropIn {
  DropIn(
    this.sdkVersionNumberProvider,
    this.dropInFlutterApi,
    this.dropInPlatformApi,
  ) {
    DropInFlutterInterface.setup(dropInFlutterApi);
  }

  final PaymentOutcomeHandler _paymentFlowOutcomeHandler =
      PaymentOutcomeHandler();
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

    dropInPlatformApi.startDropInSessionPayment(
      dropInConfiguration.toDTO(sdkVersionNumber),
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
            resultCode: paymentResultDTO.result?.resultCode ?? "",
            order: paymentResultDTO.result?.order?.fromDTO(),
          );
      }
    });
  }

  Future<PaymentResult> startDropInAdvancedFlowPayment(
    DropInConfiguration dropInConfiguration,
    String paymentMethodsResponse,
    AdvancedCheckout dropInAdvanced,
  ) async {
    adyenLogger.print("Start Drop-in advanced flow");
    final dropInAdvancedFlowCompleter = Completer<PaymentResultDTO>();
    final sdkVersionNumber =
        await sdkVersionNumberProvider.getSdkVersionNumber();

    dropInPlatformApi.startDropInAdvancedPayment(
      dropInConfiguration.toDTO(sdkVersionNumber),
      paymentMethodsResponse,
    );

    dropInFlutterApi.dropInAdvancedFlowPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    dropInFlutterApi.dropInAdvancedFlowPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.paymentComponent:
          await _handlePaymentComponent(event, dropInAdvanced.postPayments);
        case PlatformCommunicationType.additionalDetails:
          await _handleAdditionalDetails(
              event, dropInAdvanced.postPaymentsDetails);
        case PlatformCommunicationType.result:
          _handleResult(dropInAdvancedFlowCompleter, event);
        case PlatformCommunicationType.deleteStoredPaymentMethod:
          _onDeleteStoredPaymentMethodCallback(
            event,
            dropInConfiguration.storedPaymentMethodConfiguration,
          );
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
    Future<PaymentOutcome> Function(String paymentComponentJson) postPayments,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Payment data is not provided.");
      }

      final PaymentOutcome paymentOutcome = await postPayments(event.data!);
      PaymentOutcomeDTO paymentOutcomeDTO =
          _paymentFlowOutcomeHandler.mapToPaymentOutcomeDTO(paymentOutcome);
      dropInPlatformApi.onPaymentsResult(paymentOutcomeDTO);
    } catch (error) {
      String errorMessage = error.toString();
      adyenLogger.print("Failure in postPayments, $errorMessage");
      dropInPlatformApi.onPaymentsResult(PaymentOutcomeDTO(
        paymentResultType: PaymentResultType.error,
        error: ErrorDTO(
          errorMessage: errorMessage,
          reason: "Failure in postPayments, $errorMessage",
          dismissDropIn: false,
        ),
      ));
    }
  }

  Future<void> _handleAdditionalDetails(
    PlatformCommunicationModel event,
    Future<PaymentOutcome> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    try {
      if (event.data == null) {
        throw Exception("Additional data is not provided.");
      }

      final PaymentOutcome paymentFlowOutcome =
          await postPaymentsDetails(event.data!);
      PaymentOutcomeDTO paymentOutcomeDTO =
          _paymentFlowOutcomeHandler.mapToPaymentOutcomeDTO(paymentFlowOutcome);
      dropInPlatformApi.onPaymentsDetailsResult(paymentOutcomeDTO);
    } catch (error) {
      String errorMessage = error.toString();
      adyenLogger.print("Failure in postPaymentsDetails, $errorMessage");
      dropInPlatformApi.onPaymentsDetailsResult(PaymentOutcomeDTO(
        paymentResultType: PaymentResultType.error,
        error: ErrorDTO(
          errorMessage: errorMessage,
          reason: "Failure in postPaymentsDetails, $errorMessage}",
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

// bool isRemoveStoredPaymentMethodEnabled(
//     DropInConfiguration dropInConfiguration,
//     ) {
//   return dropInConfiguration.storedPaymentMethodConfiguration
//       ?.deleteStoredPaymentMethodCallback !=
//       null &&
//       dropInConfiguration.storedPaymentMethodConfiguration
//           ?.isRemoveStoredPaymentMethodEnabled ==
//           true;
// }
}
