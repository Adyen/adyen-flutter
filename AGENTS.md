# AGENTS.md - LLM Guidelines for adyen-flutter

This document provides rules and context for LLMs working on this project.

## Project Overview

**adyen-flutter** is a Flutter plugin for integrating Adyen Checkout into mobile applications. It
wraps the native Adyen Android and iOS SDKs, exposing them to Flutter via platform channels.

**Supported Platforms:** Android and iOS **only**. Do not implement or consider other platforms (
web, desktop, etc.).

## Project Structure

```
adyen-flutter/
├── lib/                              # Dart code
│   ├── adyen_checkout.dart           # Public API entry point
│   └── src/
│       ├── common/                   # Shared models and utilities
│       │   └── model/                # Dart model classes
│       ├── components/               # Individual payment components
│       ├── drop_in/                  # Drop-in integration
│       ├── generated/                # Pigeon-generated Dart code (DO NOT EDIT)
│       ├── logging/                  # Logging utilities
│       └── util/                     # Utility classes
├── pigeons/
│   └── platform_api.dart             # Pigeon API definitions (DTOs + interfaces)
├── android/
│   └── src/main/kotlin/com/adyen/checkout/flutter/
│       ├── generated/                # Pigeon-generated Kotlin code (DO NOT EDIT)
│       ├── dropIn/                   # Drop-in implementation
│       ├── components/               # Component implementations
│       └── utils/                    # Utility classes
├── ios/adyen_checkout/
│   └── Sources/adyen_checkout/
│       └── generated/                # Pigeon-generated Swift code (DO NOT EDIT)
└── example/                          # Example Flutter app
```

## Planning Flutter Features

- **[Write the plan]** Store implementation plans in the appropriate plan folder.
- **[Problem statement + non-goals]** Start the plan with a short problem statement and explicit
  non-goals/out-of-scope.
- **[Public API sketch first]** Define the intended Dart-facing API early (types + a short usage
  snippet). Keep it Flutter-idiomatic and minimal.
- **[Ownership + data flow]** Decide and document what happens in Flutter vs native.
- **[Acceptance criteria]** Add a small checklist of observable behaviors, including
  backwards-compat expectations ("when omitted, existing behavior is unchanged").
- **[Clarify unknowns]** Ask questions when requirements are unclear instead of making assumptions.
- **[Phase-based delivery]** Break work into phases that can be completed and validated
  independently. A good default for cross-platform features is:
    - **[Flutter models]** Public Dart API models.
    - **[Pigeon DTOs + codegen]** Define DTOs in `pigeons/platform_api.dart`, then generate.
    - **[Dart DTO mapping]** Map public models to DTOs in `lib/src/util/dto_mapper.dart`.
    - **[Android mapping]** Map DTOs to Android SDK types.
    - **[iOS mapping]** Map DTOs to iOS SDK types.
    - **[Finalization]** Exports, tests, example usage, docs, changelog.
- **[Keep the public API clean]** Prefer a Flutter-idiomatic abstraction (simple Dart models) and do
  the complex mapping internally. Avoid exposing native SDK configuration graphs directly.
- **[Backwards compatibility]** New fields should be optional and default to current behavior when
  omitted.
- **[DTO structure]** When adding platform configuration, design DTOs to match the native SDK
  structure the platform code needs, minimizing transformation on native.
- **[Named parameters for DTOs]** Prefer named parameters when constructing DTOs (especially
  Pigeon-generated DTOs) and any constructors with many fields. This improves readability and avoids
  breakage when constructor signatures change.
- **[Value/format decisions]** Decide early where conversions happen (e.g., `Color` to hex string,
  `double` to `int` rounding) and keep that logic in one place.
- **[Validation strategy]** Validate obvious invalid values on the Flutter side where feasible (for
  clearer errors), while keeping defaults/omitted values delegated to the native SDK.
- **[Testing + manual verification]** Plan both unit tests (Flutter mapping) and manual verification
  steps (Android + iOS), especially for UI changes.
- **[Risks + mitigations]** List the top risks (platform differences, invalid values, SDK
  limitations) and how you’ll validate/mitigate.
- **[Done definition]** End the plan with “done when” items (codegen committed, tests passing,
  example updated, docs/changelog updated).

## Idiomatic Flutter Practices

### General

- **Effective Dart**: Follow [Effective Dart](https://dart.dev/effective-dart) guidelines.
- **Lints**: Respect the `flutter_lints` rules configured in `analysis_options.yaml`.
- **Asynchrony**: Use `async`/`await` for better readability over `.then()`.
- **Null Safety**: Avoid force unwrapping (`!`). Handle nulls gracefully.

### Plugin Development

- **Public API**: Expose clean, idiomatic Dart models to the user. Do not expose DTOs or internal
  implementation details.
- **Error Handling**: Translate native errors into meaningful Dart exceptions.
- **Platform Views**: Ensure proper lifecycle management (creation, updates, disposal) to prevent
  memory leaks.

## Platform Communication with Pigeon

This project uses **Pigeon** for type-safe platform channel communication between Flutter and native
platforms.

### Key File

`pigeons/platform_api.dart` - Contains all DTOs (Data Transfer Objects) and interface definitions.

### Adding New Platform Communication

1. **Define DTOs** in `pigeons/platform_api.dart`:
    - Use simple classes with final fields
    - Follow naming convention: `*DTO` suffix for data classes
    - Only use supported Pigeon types (primitives, List, Map, other DTOs, enums)

2. **Define or update interfaces**:
    - `@HostApi()` - Methods called from Flutter → Native
    - `@FlutterApi()` - Methods called from Native → Flutter

3. **Run code generation**:
   ```bash
   dart run pigeon --input pigeons/platform_api.dart
   ```

4. **Implement on platforms**:
    - **Android**: Implement in Kotlin under `android/src/main/kotlin/com/adyen/checkout/flutter/`
    - **iOS**: Implement in Swift under `ios/adyen_checkout/Sources/adyen_checkout/`

5. **Create Dart model classes** (if needed) in `lib/src/common/model/` that map to/from DTOs

### DTO Mapping Pattern

- DTOs are used for Pigeon communication only
- Public Dart models exist in `lib/src/common/model/`
- **Mapper extensions** in `lib/src/util/dto_mapper.dart` convert between models and DTOs using
  `toDTO()` and `fromDTO()` extension methods
- Keep DTOs simple; put business logic in model classes

Example mapper:

```dart
// In lib/src/util/dto_mapper.dart
extension MyConfigurationMapper on MyConfiguration {
  MyConfigurationDTO toDTO() =>
      MyConfigurationDTO(
        field: field,
      );
}
```

### Example DTO Structure

```dart
// In pigeons/platform_api.dart
class ExampleConfigurationDTO {
  final String requiredField;
  final String? optionalField;

  ExampleConfigurationDTO(
    this.requiredField,
    this.optionalField,
  );
}
```

## Important Conventions

### Naming

- **DTOs**: `*DTO` suffix (e.g., `AmountDTO`, `CardConfigurationDTO`)
- **Enums**: PascalCase, defined in `platform_api.dart`
- **Interfaces**: `*PlatformInterface` for host APIs, `*FlutterInterface` for Flutter APIs

### Code Style

- **Dart**: Follow `flutter_lints` rules
- **Kotlin**: Follow project ktlint configuration
- **Swift**: Follow SwiftLint and SwiftFormat configurations

### Generated Code

**Never manually edit files in `generated/` directories:**

- `lib/src/generated/platform_api.g.dart`
- `android/src/main/kotlin/com/adyen/checkout/flutter/generated/PlatformApi.kt`
- `ios/adyen_checkout/Sources/adyen_checkout/generated/PlatformApi.swift`

## Native UI with Platform Views

All payment components that display native UI (card fields, Blik, direct/no-input methods, Google
Pay, Apple Pay) are rendered through **one generic Flutter platform view** with the view type
`AdyenCheckoutPaymentComponent`.

### Architecture Overview

```
CheckoutPaymentComponent (lib/src/components/checkout_payment_component.dart)
    │  ComponentContainer (component_container.dart)
    │
    ├── AndroidPlatformView ──► CheckoutPaymentViewFactory ──► CheckoutPaymentView
    │   (PlatformViewLink +        (android/.../components/)      └── DynamicComponentView (ComposeView)
    │    initSurfaceAndroidView)
    │
    └── IosPlatformView ──► CheckoutPaymentViewFactory ──► CheckoutPaymentView
        (UiKitView)            (ios/.../components/)          ├── ComponentWrapperView + child VC
                                                              └── ApplePayButtonView (PKPaymentButton)
```

### Key Files

| Layer                  | Android (`android/.../flutter/`)                                   | iOS (`ios/.../Sources/adyen_checkout/`)                        | Dart (`lib/src/`)                                                                    |
|------------------------|--------------------------------------------------------------------|----------------------------------------------------------------|--------------------------------------------------------------------------------------|
| Widget                 | -                                                                  | -                                                              | `components/checkout_payment_component.dart`, `components/component_container.dart` |
| Platform view wrapper  | -                                                                  | -                                                              | `components/platform/android_platform_view.dart`, `ios_platform_view.dart`          |
| View factory           | `components/CheckoutPaymentViewFactory.kt`                         | `components/CheckoutPaymentViewFactory.swift`                  | -                                                                                    |
| Native view            | `components/CheckoutPaymentView.kt`, `components/view/DynamicComponentView.kt` | `components/CheckoutPaymentView.swift`, `components/platformViewUtils/ComponentWrapperView.swift`, `components/ApplePayButtonView.swift` | -                    |
| Creation failure       | `components/FailedCheckoutPaymentView.kt`                          | -                                                              | -                                                                                    |
| Callbacks              | `components/CheckoutCallbacksBridge.kt`, `utils/CheckoutCallbacksMapper.kt` | -                                                     | -                                                                                    |
| Component registry     | `components/CheckoutComponentRegistry.kt`                          | `components/CheckoutComponentRegistry.swift`                   | -                                                                                    |
| Error codes            | `utils/ErrorCodes.kt`                                              | `utils/ErrorCodes.swift`                                       | -                                                                                    |

- The view type is defined in `Constants.checkoutPaymentComponentViewType` (Dart),
  `ComponentPlatformApi.VIEW_TYPE` (Android) and `CheckoutPaymentViewFactory.viewType` (iOS).
- Android registers the factory once in `AdyenCheckoutPlugin.onAttachedToEngine`; the factory
  reads the activity lazily at view creation. Creation failures render a
  `FailedCheckoutPaymentView` and are reported as `failure` events.
- `CheckoutComponentRegistry` is an instance, not a singleton: owned by the plugin on Android and
  created in `AdyenCheckoutPlugin.register` on iOS.
- `lib/src/components/apple_pay/model/` only holds the public Apple Pay button models (style,
  theme, type). Apple Pay is drawn natively as a `PKPaymentButton` inside `CheckoutPaymentView`;
  there is no `pay` package and no Dart-drawn payment button.

### Adding a New Payment Method with Native UI

**Do not create per-payment-method factories.** The generic `CheckoutPaymentViewFactory` /
`CheckoutPaymentView` pair renders any payment method type: `paymentMethod.type` is passed
straight to the native v6 SDK (`CheckoutTarget.PaymentMethod(...)` on Android,
`checkout.createPaymentComponent(for:)` on iOS), which resolves the concrete component.

Before adding anything, check whether the native v6 SDK (adyen-android/adyen-ios) already
registers a component for the payment method's `txVariant` in its own registry (Android:
`PaymentMethodProvider`/`*Initializer.kt` per payment method module; iOS:
`CheckoutComponentBuilder`/`PaymentMethodType`). If it does, the method should already work
through `CheckoutPaymentComponent` with no plugin changes; verify it manually (Sessions and
Advanced, both platforms). Only add plugin code if the native SDK does not support the method
generically.

### Communication Pattern

- **Flutter → Native (creation)**: `CheckoutPaymentViewParamsDTO` (`pigeons/platform_api.dart`)
  is passed as `creationParams`, encoded with `CheckoutHostApi.pigeonChannelCodec`.
- **Flutter → Native (commands)**: component submit and dispose go through `ComponentHostApi`.
- **Native → Flutter (events)**: `CheckoutEventDTO` over the `CheckoutEvents` event channel, with
  types `componentReady`, `resize`, `failure`, `complete`, `binLookup`, `binValue`.
- **Native → Flutter (callbacks)**: `onSubmit`, `onAdditionalDetails`, `onBeforeSubmit` and the
  Apple Pay callbacks go through `CheckoutCallbacksFlutterApi`.
- **Resize handling**: native views measure their content and report the height in `resize`
  events; the Dart widget updates its viewport. Android measures the Compose content height
  unconstrained and reports rounded-up dp; iOS uses `preferredContentSize` or
  `systemLayoutSizeFitting`.

### Important Notes

- View type IDs must match exactly between Dart and native code.
- The native view is recreated only when the component id changes (checkout id, payment method
  data or controller). The platform view is keyed with `ValueKey(componentId)`; do not add other
  triggers for recreation.
- Android `DynamicComponentView` disposes its composition explicitly on dispose so the native
  component is released together with the widget.
- iOS `CheckoutPaymentView` embeds the native component view controller as a child of the nearest
  parent view controller.
- Redirect returns: Android routes the intent to the active component, otherwise to all
  registered components (needed for Sessions without a controller). On iOS merchants call
  `Checkout.handleReturn(url:)`.

## Common Tasks

### Adding a New Configuration Option

1. Add field to relevant DTO in `pigeons/platform_api.dart`
2. Run `dart run pigeon --input pigeons/platform_api.dart`
3. Add corresponding field to Dart model in `lib/src/common/model/`
4. Update mapper to handle new field
5. Update Android implementation
6. Update iOS implementation
7. Add tests and update CHANGELOG.md

### Adding a New Payment Method Configuration

1. Create new DTO class in `pigeons/platform_api.dart`
2. Add to parent configuration DTO (e.g., `DropInConfigurationDTO`)
3. Run Pigeon generation
4. Create Dart model class
5. Create mapper extension
6. Implement on Android and iOS
7. Add documentation and tests

## Testing

- When creating or updating iOS tests, always follow the Adyen iOS SDK testing
  guide: https://github.com/Adyen/adyen-ios/blob/develop/TESTING.md
- Run with `flutter test`
- Test both model classes and DTO mappings

| Platform       | Where to put tests            | Notes                                                                                        |
|----------------|-------------------------------|----------------------------------------------------------------------------------------------|
| Flutter (Dart) | `test/`                       | Dart unit tests                                                                              |
| Android        | `android/src/test/kotlin/...` | JVM unit tests. If you need instrumentation tests, use `android/src/androidTest/kotlin/...`. |
| iOS            | `example/ios/RunnerTests/`    | Xcode/Swift tests for the iOS example app target.                                            |

## Checkout 2.0 alpha implementation notes

- This branch is the Flutter 2.0 v6 alpha implementation. The public entry point is `Checkout`,
  with Sessions, Advanced, generic `CheckoutPaymentComponent`, and one-shot action handling.
- Drop-in for sessions is available via `SessionCheckout.startDropIn()`; results reuse the
  `SessionCheckoutCallbacks` event path (cancel → `CheckoutError.cancellationCode`). Android
  Drop-in does not propagate `sessionResult` yet, so it is empty for Drop-in completions.
  Instant, partial-payment/order, and legacy component APIs are intentionally removed.
- Native dependencies track development builds, not a release pin: Android resolves the weekly
  Sunday snapshot (`YYYY.MM.DD-SNAPSHOT`, see `adyenSnapshotVersion` in `android/build.gradle`)
  from Central Portal Snapshots, and iOS pins `adyen-ios` `develop` to a specific commit via the
  `revision:` requirement in `ios/adyen_checkout/Package.swift`. iOS uses Swift Package Manager and
  requires iOS 16.0 or later.
- Generic native payment views are registered through `CheckoutComponentRegistry` and use
  `CheckoutPaymentView` on both platforms.
- Direct/no-input methods render their own native submit button (`showSubmitButton` default). A
  `CheckoutController` is only required when `showSubmitButton` is `false`; in that case
  no-interaction components collapse to zero height and the merchant submits via the controller.
- After changing `pigeons/platform_api.dart`, run `dart run pigeon --input pigeons/platform_api.dart`,
  then `dart format lib/src/generated/platform_api.g.dart` to normalize Pigeon output whitespace.
  Do not hand-edit generated platform files.
- Verification from the v2 package root: `flutter analyze`, `flutter test`,
  `flutter test` from `example/`, `flutter build apk --debug` from `example/`, and
  `flutter build ios --simulator --debug --no-codesign` from `example/`.
- This branch is proof-only. Never publish it to pub.dev, create a GitHub release/tag, or prepare a
  release PR. Focus on technical validation and documenting limitations.
