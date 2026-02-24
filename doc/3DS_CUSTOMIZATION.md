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
    headingTitle: 'Custom 3DS2 Title', // Optional custom title
    requestorAppURL: 'myapp://adyen-redirect', // Optional deep link
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
    cancelButtonColor: Colors.blue, // iOS only
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
    headingTitle: 'Custom 3DS2 Title', // Optional custom heading
    requestorAppURL: 'myapp://adyen-redirect', // Optional deep link
    theme: theme,
  ),
);
```

## Notes

- All properties are optional. Null values fall back to the native SDK defaults.
- Sizes are `double` in Flutter and are rounded when mapped to native SDKs.
- Colors are converted to `#AARRGGBB` hex strings to preserve alpha.
- `backgroundColor` affects both Android and iOS challenge screens.
- `headingTitle` allows customization of the 3DS2 challenge screen heading.
- `requestorAppURL` enables deep linking back to your app after 3DS2 completion.
- `cancelButtonColor` in `Adyen3DSHeaderTheme` is iOS-only.

## Configuration Options

### ThreeDS2Configuration

- `headingTitle`: Custom title for the 3DS2 challenge screen header
- `requestorAppURL`: Deep link URL for returning to your app after 3DS2
- `theme`: `Adyen3DSTheme` instance for visual customization

### Adyen3DSTheme

- `backgroundColor`: Screen background color (Android only)
- `textColor`: Primary text color for labels and content
- `headerTheme`: Customization for the challenge screen header
- `descriptionTheme`: Styling for description text and titles
- `inputDecorationTheme`: Text input field styling
- `primaryButtonTheme`: Submit/continue/next button styling
- `secondaryButtonTheme`: Cancel/resend/out-of-band button styling
- `selectionItemTheme`: Radio/selection item styling

### Platform-Specific Notes

**iOS:**
- `cancelButtonColor` in header theme is iOS-specific
