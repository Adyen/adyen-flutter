# Migrating to Checkout 2.0

Checkout 2.0 is a breaking prerelease aligned with the public Adyen Android and iOS v6 alpha APIs.
It supports Android and iOS only.

## Entry points

Replace the v1 session and advanced setup calls:

```dart
AdyenCheckout.session.setup(...)
AdyenCheckout.advanced.setup(...)
```

with the single `AdyenCheckout.instance.setup(...)` entry point, which returns a `Checkout` (the
native v6 name; it replaces `SessionCheckout`). Callbacks and results follow the native names:
`CheckoutCallbacks` and `CheckoutResult` replace `SessionCheckoutCallbacks` and
`SessionCheckoutResult`.

```dart
final checkout = await AdyenCheckout.instance.setup(
  sessionResponse: sessionResponse,
  configuration: configuration,
  callbacks: CheckoutCallbacks(
    onComplete: onSessionComplete,
    onFailure: onFailure,
  ),
);
```

The Advanced flow is not available in Checkout 2.0. The native Android and iOS v6 SDKs no longer
expose it publicly, so `setupAdvanced`, `AdvancedCheckout`, `AdvancedCheckoutCallbacks`,
`SubmitResult` and `PaymentComponentData` have been removed. Use Sessions instead.

`AdyenCheckout.instance.handleAction` replaces the legacy standalone action component and returns an
`AdvancedCheckoutResult`. The action callback is supplied directly to the one-shot call.

## Components

Replace `AdyenComponent` with `CheckoutPaymentComponent`. The component no longer accepts a
configuration or result callback:

```dart
CheckoutPaymentComponent(
  checkout: checkout,
  paymentMethod: checkout.paymentMethods.first,
  controller: controller,
);
```

Completion and failure are delivered through the callback object passed during setup. Use
`CheckoutController` for direct methods and custom submit buttons.

### Instant methods

The separate v1 Instant API is replaced by the same generic component used for other payment
methods. Select iDEAL, PayPal, Klarna, Pay by Bank, or TWINT from `checkout.paymentMethods`, mount
`CheckoutPaymentComponent` with a `CheckoutController`, and show a merchant button only when
`controller.requiresUserInteraction == false`. Keep the zero-height component mounted while the
payment is active so native Checkout can present and complete actions.

Future native SDK versions are expected to provide their own button. A future dependency update will
replace the temporary Flutter button with that native UI while preserving the same generic
component/controller API; no payment-method-specific Flutter API is required.

## Models and callbacks

- Raw payment-method maps become `PaymentMethods`, `PaymentMethod`, and `StoredPaymentMethod`.
- Action callback payloads become `ActionComponentData`; the data is available through its
  unmodifiable `data` map.
- `PaymentEvent` becomes `AdditionalDetailsResult`, `CheckoutResult`, and `CheckoutError`.
- Payment-method callbacks no longer live on the payment-method configurations. Apple Pay callbacks
  (`onSelectShippingMethod`, `onSelectShippingContact`, `onChangeCouponCode`, `onAuthorize`) move
  from `ApplePayConfiguration` to `ApplePayCallbacks`, and card BIN callbacks (`onBinChange`,
  `onBinLookup`) move from `CardConfiguration` to `CardCallbacks`. Pass them through
  `CheckoutCallbacks(applePay: ..., card: ...)`, mirroring the native v6 SDKs.
- Card validators return `bool` and expiry validation requires two-digit `MM` and `YY` strings.
- `AdyenCheckout.instance.getReturnUrl()` is removed. Configure the return URL in the backend and forward incoming
  native URL or intent events to the native Checkout API in the host application.

## Removed APIs

Drop-in, separate Instant APIs, partial-payment/order APIs, the legacy action component, generated
Pigeon types, granular legacy 3DS2 appearance configuration, and CocoaPods integration are not part
of the 2.0 alpha.

## Configuration changes

`CheckoutConfiguration` now accepts only the v6-aligned fields:

- `environment` and `clientKey`;
- `analyticsConfiguration` and `showSubmitButton`;
- Card, Apple Pay, and Android-only Google Pay configuration.

Unsupported fields are removed rather than silently ignored. The top-level `amount` and
`countryCode` are gone: move them into `ApplePayConfiguration` (`amount` and `countryCode`, both
required) and `GooglePayConfiguration` (`countryCode`, required). Sessions supply the amount
natively. Google Pay is supported on Android only.
