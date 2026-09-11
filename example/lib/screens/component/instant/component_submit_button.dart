import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/material.dart';

class ComponentUnavailableMessage extends StatelessWidget {
  final String paymentMethodName;

  const ComponentUnavailableMessage({
    required this.paymentMethodName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$paymentMethodName is not available.'));
  }
}

class ControlledCheckoutPaymentComponent extends StatefulWidget {
  final CheckoutFlow checkout;
  final PaymentMethod paymentMethod;

  const ControlledCheckoutPaymentComponent({
    required this.checkout,
    required this.paymentMethod,
    super.key,
  });

  @override
  State<ControlledCheckoutPaymentComponent> createState() =>
      _ControlledCheckoutPaymentComponentState();
}

class _ControlledCheckoutPaymentComponentState
    extends State<ControlledCheckoutPaymentComponent> {
  final CheckoutController _controller = CheckoutController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckoutPaymentComponent(
          checkout: widget.checkout,
          paymentMethod: widget.paymentMethod,
          controller: _controller,
        ),
        ComponentSubmitButton(
          controller: _controller,
          paymentMethodName: widget.paymentMethod.name,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ComponentSubmitButton extends StatefulWidget {
  final CheckoutController controller;
  final String paymentMethodName;

  const ComponentSubmitButton({
    required this.controller,
    required this.paymentMethodName,
    super.key,
  });

  @override
  State<ComponentSubmitButton> createState() => _ComponentSubmitButtonState();
}

class _ComponentSubmitButtonState extends State<ComponentSubmitButton> {
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final isDirect = widget.controller.isReady &&
            widget.controller.requiresUserInteraction == false;
        if (!isDirect) return const SizedBox.shrink();

        return FilledButton(
          onPressed: _submitted ? null : _submit,
          child: Text('Pay with ${widget.paymentMethodName}'),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    await widget.controller.submit();
  }
}
