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

## Manual customization

```dart
final theme = Adyen3DSTheme(
  primaryColor: Colors.green,
  onPrimaryColor: Colors.white,
  screenBackgroundColor: Colors.white,
  textColor: Colors.black87,
  inputDecorationTheme: Adyen3DSInputDecorationTheme(
    borderColor: Colors.grey,
    cornerRadius: 4,
  ),
  buttonCornerRadius: 8,
  labelFontSize: 14,
  buttonFontSize: 15,
  submitButtonTheme: Adyen3DSButtonTheme(
    backgroundColor: Colors.green,
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
