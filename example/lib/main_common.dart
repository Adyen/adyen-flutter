import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Action;

void mainCommon(Service service) {
  runApp(CheckoutExample(service: service));
}

Future<AdvancedCheckoutResult> handleStandaloneAction({
  required Map<String, dynamic> actionJson,
  required CheckoutConfiguration configuration,
  required Future<AdditionalDetailsResult> Function(ActionComponentData data)
      onAdditionalDetails,
}) =>
    Checkout.handleAction(
      action: Action.fromJson(actionJson),
      configuration: configuration,
      onAdditionalDetails: onAdditionalDetails,
    );

class CheckoutExample extends StatefulWidget {
  final Service service;

  const CheckoutExample({required this.service, super.key});

  @override
  State<CheckoutExample> createState() => _CheckoutExampleState();
}

class _CheckoutExampleState extends State<CheckoutExample> {
  CheckoutFlow? _checkout;
  String? _error;
  bool _loading = false;

  CheckoutConfiguration get _configuration => CheckoutConfiguration(
        environment: Config.environment,
        clientKey: Config.clientKey,
        amount: Config.amount,
        countryCode: Config.countryCode,
        cardConfiguration: const CardConfiguration(
          showCardholderName: true,
          showStorePaymentMethod: false,
          showSupportedCardBrandLogos: true,
        ),
        googlePayConfiguration: defaultTargetPlatform == TargetPlatform.android
            ? const GooglePayConfiguration(
                googlePayEnvironment: Config.googlePayEnvironment,
                emailRequired: true,
              )
            : null,
        applePayConfiguration: defaultTargetPlatform == TargetPlatform.iOS &&
                Config.merchantId.isNotEmpty
            ? const ApplePayConfiguration(
                merchantId: Config.merchantId,
                merchantName: Config.merchantName,
                applePaySummaryItems: [
                  ApplePaySummaryItem(
                    label: Config.merchantName,
                    amount: Config.amount,
                    type: ApplePaySummaryItemType.definite,
                  ),
                ],
              )
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xFF00112C)),
      home: Scaffold(
        appBar: AppBar(title: const Text('Checkout 2.0 alpha example')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final checkout = _checkout;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error case final error?)
            Text(error,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton(
            onPressed: _startSession,
            child: const Text('Sessions checkout'),
          ),
          FilledButton(
            onPressed: _startAdvanced,
            child: const Text('Advanced checkout'),
          ),
          if (checkout case final checkout?) ...[
            Text('Checkout ${checkout.id}'),
            for (final method in checkout.paymentMethods)
              CheckoutPaymentComponent(
                checkout: checkout,
                paymentMethod: method,
              ),
            for (final method in checkout.storedPaymentMethods)
              CheckoutPaymentComponent(
                checkout: checkout,
                paymentMethod: method,
              ),
            const Text(
                'Standalone action example: handleStandaloneAction(actionJson: ...).'),
          ],
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    await _run(() async {
      final response = await widget.service.createSession({
        'merchantAccount': Config.merchantAccount,
        'amount': Config.amount.toJson(),
        'countryCode': Config.countryCode,
        'shopperLocale': Config.shopperLocale,
        'returnUrl': Config.iOSReturnUrl,
        'reference': 'flutter-session-${DateTime.now().millisecondsSinceEpoch}',
        'channel': _channel,
      });
      final checkout = await Checkout.setup(
        sessionResponse: SessionResponse.fromJson(response),
        configuration: _configuration,
        callbacks: SessionCheckoutCallbacks(
          onComplete: _onSessionComplete,
          onFailure: _onFailure,
          onBeforeSubmit: (data) async => BeforeSubmitProceed(data: data),
        ),
      );
      _replaceCheckout(checkout);
    });
  }

  Future<void> _startAdvanced() async {
    await _run(() async {
      final response = await widget.service.fetchPaymentMethods({
        'merchantAccount': Config.merchantAccount,
        'amount': Config.amount.toJson(),
        'countryCode': Config.countryCode,
        'channel': _channel,
      });
      final checkout = await Checkout.setupAdvanced(
        paymentMethods: PaymentMethods.fromJson(response),
        configuration: _configuration,
        callbacks: AdvancedCheckoutCallbacks(
          onSubmit: _onSubmit,
          onAdditionalDetails: _onAdditionalDetails,
          onComplete: _onAdvancedComplete,
          onFailure: _onFailure,
        ),
      );
      _replaceCheckout(checkout);
    });
  }

  Future<SubmitResult> _onSubmit(PaymentComponentData data) async {
    final response = await widget.service.postPayments({
      'merchantAccount': Config.merchantAccount,
      'amount': Config.amount.toJson(),
      'countryCode': Config.countryCode,
      'returnUrl': Config.iOSReturnUrl,
      ...data.data,
    });
    return _submitResult(response);
  }

  Future<AdditionalDetailsResult> _onAdditionalDetails(
    ActionComponentData data,
  ) async {
    final response = await widget.service.postPaymentsDetails(data.data);
    return AdditionalDetailsResult.completion(
      resultCode: response['resultCode'] as String? ?? 'Error',
    );
  }

  SubmitResult _submitResult(Map<String, dynamic> response) {
    final action = response['action'];
    if (action is Map) {
      return SubmitResult.action(
        Action.fromJson(Map<String, dynamic>.from(action)),
      );
    }
    return SubmitResult.completion(
      resultCode: response['resultCode'] as String? ?? 'Error',
    );
  }

  void _onSessionComplete(SessionCheckoutResult result) {
    _showMessage('Session completed: ${result.resultCode}');
  }

  void _onAdvancedComplete(AdvancedCheckoutResult result) {
    _showMessage('Advanced checkout completed: ${result.resultCode}');
  }

  void _onFailure(CheckoutError error) {
    setState(
        () => _error = '${error.code}: ${error.message ?? 'Checkout failed.'}');
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await operation();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _replaceCheckout(CheckoutFlow checkout) {
    _checkout?.dispose();
    setState(() => _checkout = checkout);
  }

  String get _channel =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
