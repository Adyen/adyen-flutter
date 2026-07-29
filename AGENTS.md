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

Payment components that display native UI (e.g., card input fields) use **Flutter Platform Views**
to embed native Android/iOS views within Flutter widgets.

### Architecture Overview

```
Flutter Widget (Dart)
    │
    ├── AndroidPlatformView ──► PlatformViewFactory ──► Native Android View
    │   (lib/src/components/platform/)     (android/.../components/)
    │
    └── IosPlatformView ──► FlutterPlatformViewFactory ──► Native iOS View
        (lib/src/components/platform/)     (ios/.../components/)
```

### Key Files

| Layer                    | Android                                   | iOS                                          | Dart                                                                               |
|--------------------------|-------------------------------------------|----------------------------------------------|------------------------------------------------------------------------------------|
| Platform View Wrapper    | -                                         | -                                            | `lib/src/components/platform/android_platform_view.dart`, `ios_platform_view.dart` |
| View Factory             | `components/v2/AdyenComponentFactory.kt`  | `components/v2/AdyenComponentFactory.swift`  | -                                                                                  |
| Native View Wrapper      | `components/view/DynamicComponentView.kt` | `components/ComponentWrapperView.swift`      | -                                                                                  |
| Component Implementation | `components/v2/AdyenComponent.kt`         | `components/v2/AdyenComponent.swift`         | `lib/src/v2/adyen_component.dart`, `adyen_base_component.dart`                     |

Note: all payment methods rendered as native platform views (Card, Blik, and any future
method with the same shape) go through this **single generic** factory/component/wrapper —
there is no longer a dedicated per-payment-method `CardComponentFactory`/`BlikComponentFactory`
etc. `PlatformMethodResponse`/`paymentMethod.type` is passed straight through to the native
v6 SDK, which resolves the concrete component internally (see
`components/view/DynamicComponentView.kt`'s `addV6Component`). Apple Pay/Google Pay are a
separate case (Dart-drawn buttons, not platform views) — see
`lib/src/components/apple_pay/`, `lib/src/components/google_pay/`.

### Adding a New Payment Method with Native UI

As of the v6 generic component consolidation (Card and Blik were the first to migrate),
**do not create a new per-payment-method `PlatformViewFactory`/`FlutterPlatformViewFactory`.**
The existing generic factory/component pair
(`components/v2/AdyenComponentFactory.kt`+`AdyenComponent.kt` on Android,
`components/v2/AdyenComponentFactory.swift`+`AdyenComponent.swift` on iOS) already renders
*any* payment method type as a native platform view, by passing `paymentMethod.type`
straight through to the native v6 SDK (`CheckoutTarget.PaymentMethod(...)` on Android,
`checkout.createPaymentComponent(for:)` on iOS), which resolves the concrete component
internally. This was confirmed empirically for Google Pay on Android without any plugin
code changes (see `Plans/Unify Payment Method Components into AdyenComponent.md` in the
Obsidian vault).

Before adding anything, check whether the native v6 SDK (adyen-android/adyen-ios) already
registers a component for the new payment method's `txVariant` in its own generic component
registry (Android: `PaymentMethodProvider`/`*Initializer.kt` per payment method module; iOS:
`CheckoutComponentBuilder`/`PaymentMethodType`). If it does, the payment method should
**already work** through `AdyenComponent`/`lib/src/v2/adyen_component.dart` with no plugin
changes at all — just verify it manually (both flows, both platforms) rather than writing
new factory code.

Only fall back to a dedicated per-payment-method implementation if the native v6 SDK does
**not** yet support the method generically, or if it renders as something other than an
embeddable platform view (e.g. Apple Pay/Google Pay render as Dart-drawn buttons via the
`pay` package plus an availability/instant-payment channel, not a platform view — see
`lib/src/components/apple_pay/`, `lib/src/components/google_pay/`,
`android/.../components/googlepay/GooglePayComponentManager.kt`,
`ios/.../components/instant/` for that different pattern).

### Communication Pattern

- **Flutter → Native**: Pass data via `creationParams` when creating the view
- **Native → Flutter**: Use `ComponentFlutterInterface.onComponentCommunication()` for events.
    - Events: `onSubmit`, `additionalDetails`, `loading`, `result`, `resize`, `binLookup`,
      `binValue`, `availability`
- **Resize handling**: Native views report height changes; Dart widget updates viewport accordingly

### Important Notes

- View type IDs must match exactly between Dart and native code
- Use `ComponentFlutterInterface.pigeonChannelCodec` as the message codec
- Handle view disposal properly to avoid memory leaks
- Calculate initial view height per platform (Android/iOS have different component heights)

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
