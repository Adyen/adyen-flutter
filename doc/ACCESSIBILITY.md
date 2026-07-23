# Drop-in keyboard accessibility on iOS

When using iOS Full Keyboard Access with Drop-in, wrap the `MaterialApp.builder` child with `AdyenDropInFocusScope`.

```dart
import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      builder: (context, child) =>
          AdyenDropInFocusScope(child: child!),
      home: const CheckoutScreen(),
    ),
  );
}
```

`AdyenDropInFocusScope` automatically excludes the Flutter navigator and active route from accessibility semantics and Flutter focus traversal while native iOS Drop-in is visible. This lets iOS Full Keyboard Access navigate the native Drop-in UI without background Flutter controls competing for focus.

The scope restores Flutter semantics and focus traversal when Drop-in closes. You do not need to manage focus nodes, active state, keyboard events, or platform channels.

## Placement

Use `MaterialApp.builder` so the scope wraps the Navigator and active route:

```text
MaterialApp
  └── AdyenDropInFocusScope
       └── Navigator
            └── Drop-in launch route
```

Wrapping only the widget that calls `startDropIn` is not sufficient because Flutter navigation controls can remain focus candidates.

## Platform behavior

The scope changes behavior only on iOS. On Android, it returns its child unchanged.

## Testing

To test on iOS:

1. Enable **Settings > Accessibility > Keyboards > Full Keyboard Access**.
2. Open Drop-in.
3. Use the configured Full Keyboard Access commands to navigate native Drop-in controls.
4. Close Drop-in and verify that Flutter controls are reachable again.
