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
