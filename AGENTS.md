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
| View Factory             | `components/card/CardComponentFactory.kt` | `components/card/CardComponentFactory.swift` | -                                                                                  |
| Native View Wrapper      | `components/view/DynamicComponentView.kt` | `components/ComponentWrapperView.swift`      | -                                                                                  |
| Component Implementation | `components/card/BaseCardComponent.kt`    | `components/card/BaseCardComponent.swift`    | `lib/src/components/card/base_card_component.dart`                                 |

### Adding a New Payment Method with Native UI

1. **Define a unique view type ID** (used to match Flutter widget with native factory):
   ```kotlin
   // Android
   const val MY_COMPONENT_ID = "myComponentId"
   ```
   ```swift
   // iOS
   static let myComponentId = "myComponentId"
   ```

2. **Create the Dart widget** in `lib/src/components/`:
    - Create a new StatefulWidget that builds platform-specific views
    - Use `AndroidPlatformView` / `IosPlatformView` based on `defaultTargetPlatform`
    - Pass configuration via `creationParams` map (use DTOs and mappers from `dto_mapper.dart`)
    - Use the same `viewType` string as the native factory ID
    - Note: `BaseCardComponent` is specific to card components, not a general base class

3. **Create Android PlatformViewFactory** in `android/.../components/`:
   ```kotlin
   class MyComponentFactory(...) : PlatformViewFactory(ComponentFlutterInterface.pigeonChannelCodec) {
       override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
           // Parse creationParams and return native view
       }
   }
   ```

4. **Register Android factory** in a manager class:
   ```kotlin
   flutterPluginBinding?.platformViewRegistry?.registerViewFactory(
       MY_COMPONENT_ID,
       MyComponentFactory(...)
   )
   ```

5. **Create iOS FlutterPlatformViewFactory** in `ios/.../components/`:
   ```swift
   class MyComponentFactory: NSObject, FlutterPlatformViewFactory {
       func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
           // Parse arguments and return native view
       }
   }
   ```

6. **Register iOS factory** in `AdyenCheckoutPlugin.swift`:
   ```swift
   registrar.register(myComponentFactory, withId: MyComponentFactory.myComponentId)
   ```

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

- Unit tests in `test/`
- Run with `flutter test`
- Test both model classes and DTO mappings
