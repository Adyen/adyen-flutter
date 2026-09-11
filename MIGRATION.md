# Migrating to Checkout 2.0

Checkout 2.0 is a breaking prerelease aligned with the public Adyen Android and iOS v6 alpha APIs.
It supports Android and iOS only.

## Entry points

Replace the singleton manager API:

```dart
AdyenCheckout.instance
AdyenCheckout.session.setup(...)
AdyenCheckout.advanced.setup(...)
```

with the singleton `Checkout.instance` entry point:

```dart
final sessionCheckout = await Checkout.instance.setup(
  sessionResponse: sessionResponse,
  configuration: configuration,
  callbacks: SessionCheckoutCallbacks(
    onComplete: onSessionComplete,
    onFailure: onFailure,
  ),
);

final advancedCheckout = await Checkout.instance.setupAdvanced(
  paymentMethods: PaymentMethods.fromJson(paymentMethodsJson),
  configuration: configuration,
  callbacks: AdvancedCheckoutCallbacks(
    onSubmit: onSubmit,
    onAdditionalDetails: onAdditionalDetails,
    onComplete: onAdvancedComplete,
    onFailure: onFailure,
  ),
);
```

`Checkout.instance.handleAction` replaces the legacy standalone action component and returns an
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
- Callback payloads become `PaymentComponentData` and `ActionComponentData`; submit data is available
  through their unmodifiable `data` maps.
- `PaymentEvent` becomes `SubmitResult`, `AdditionalDetailsResult`, checkout result models, and
  `CheckoutError`.
- Card validators return `bool` and expiry validation requires two-digit `MM` and `YY` strings.
- `Checkout.getReturnUrl()` is removed. Configure the return URL in the backend and forward incoming
  native URL or intent events to the native Checkout API in the host application.

## Removed APIs

Drop-in, separate Instant APIs, partial-payment/order APIs, the legacy action component, generated
Pigeon types, granular legacy 3DS2 appearance configuration, and CocoaPods integration are not part
of the 2.0 alpha.

## Configuration changes

`CheckoutConfiguration` now accepts only the v6-aligned fields:

- `environment`, `clientKey`, optional `amount`, and optional `countryCode`;
- `analyticsConfiguration` and `showSubmitButton`;
- Card, Apple Pay, and Android-only Google Pay configuration.

Unsupported fields are removed rather than silently ignored. Apple Pay requires an amount and
country code when it is configured. Google Pay is supported on Android only.
