# 3DS2 UI customization

Use `Adyen3DSTheme` to customize the 3DS2 challenge screens. The theme is mapped in Dart to the
native SDK customization structures, so native code receives ready-to-apply values.

## Quick start

```dart
final dropInConfiguration = DropInConfiguration(
  environment: Environment.test,
  clientKey: clientKey,
  countryCode: 'NL',
  threeDS2Configuration: ThreeDS2Configuration(
    theme: Adyen3DSTheme.fromThemeData(Theme.of(context)),
  ),
);
```

`fromThemeData` uses Flutter defaults to keep UI consistent with your app:

- `scaffoldBackgroundColor` for screen background
- `textTheme.bodyMedium` and `titleSmall` for text colors and sizes
- `appBarTheme` for heading background and text colors
- `inputDecorationTheme` for borders and labels
- `colorScheme` for button colors and selection states

## Manual customization

```dart
final theme = Adyen3DSTheme(
  backgroundColor: Colors.white,
  textColor: Colors.black87,
  headerTheme: const Adyen3DSHeaderTheme(
    backgroundColor: Colors.green,
    textColor: Colors.white,
  ),
  inputDecorationTheme: Adyen3DSInputDecorationTheme(
    borderColor: Colors.grey,
    cornerRadius: 4,
    textColor: Colors.black87,
  ),
  descriptionTheme: const Adyen3DSDescriptionTheme(
    titleTextColor: Colors.black,
    textColor: Colors.black54,
  ),
  primaryButtonTheme: const Adyen3DSButtonTheme(
    backgroundColor: Colors.green,
    textColor: Colors.white,
    cornerRadius: 8,
    fontSize: 15,
  ),
  secondaryButtonTheme: const Adyen3DSButtonTheme(
    backgroundColor: Colors.white,
    textColor: Colors.black87,
    cornerRadius: 8,
    fontSize: 15,
  ),
  selectionItemTheme: const Adyen3DSSelectionItemTheme(
    selectionIndicatorTintColor: Colors.green,
    highlightedBackgroundColor: Colors.greenAccent,
    textColor: Colors.black87,
  ),
);

final configuration = DropInConfiguration(
  environment: Environment.test,
  clientKey: clientKey,
  countryCode: 'NL',
  threeDS2Configuration: ThreeDS2Configuration(
    requestorAppURL: 'myapp://adyen-redirect',
    theme: theme,
  ),
);
```

## Notes

- All properties are optional. Null values fall back to the native SDK defaults.
- Sizes are `double` in Flutter and are rounded when mapped to native SDKs.
- Colors are converted to `#AARRGGBB` hex strings to preserve alpha.
- `backgroundColor` affects Android; iOS uses native defaults for the screen.
