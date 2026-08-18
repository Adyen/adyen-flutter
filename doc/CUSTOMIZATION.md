## UI Customization

### Android

To customize Adyen Checkout on Android, define an `AdyenCheckout` style in your app's
`android/app/src/main/res/values/styles.xml`. App resources take precedence over the plugin default.

```xml
<style name="AdyenCheckout" parent="Theme.MaterialComponents.DayNight">
    <item name="colorPrimary">@color/your_primary_color</item>
</style>
```

Use `AdyenCheckout` rather than the generic `AppTheme` style. Android merges resources from every
dependency, so an `AppTheme` supplied by an unrelated dependency can produce an unexpected Checkout
theme. If you currently customize Checkout through `AppTheme`, move those attributes to
`AdyenCheckout` instead.

The `AdyenCheckout` style customizes Drop-in and defines the default styling used by Components.

Standalone Components require Flutter's Android `NormalTheme` to inherit from a Material Components
theme. Update the style in every qualified resource directory where it is declared, including
`values` and `values-night`:

```xml
<style name="NormalTheme" parent="Theme.MaterialComponents.DayNight.NoActionBar">
    <item name="android:windowBackground">?android:colorBackground</item>
</style>
```

`NormalTheme` can inherit from `Theme.MaterialComponents` directly or through a custom theme, as shown
in the [example app](https://github.com/Adyen/adyen-flutter/blob/main/example/android/app/src/main/res/values/styles.xml#L15-L23).
This ensures that dynamically loaded Component views can resolve all required Material theme attributes.
For all available attributes and component-specific styles, see the Android SDK
[customization docs](https://github.com/Adyen/adyen-android/blob/main/docs/UI_CUSTOMIZATION.md).

### iOS

On your iOS layer e.g. in the AppDelegate, set the `dropInStyle` or the `cardComponentStyle` of
AdyenAppearance depending on your integration.
The SDK will use your provided style and apply it automatically. Feel free to check out the example
app [implementation](https://github.com/Adyen/adyen-flutter/blob/main/example/ios/Runner/AppDelegate.swift#L36-L50).

Drop-in:

```swift
import Adyen

// Use canImport for projects that utilize SPM.
#if canImport(adyen_checkout)
    import adyen_checkout
#endif
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif

var dropInStyle = DropInComponent.Style()
dropInStyle.formComponent.mainButtonItem.button.backgroundColor = .black
dropInStyle.formComponent.mainButtonItem.button.title.color = .white
AdyenAppearance.dropInStyle = dropInStyle
```

Card Component:

```swift
import Adyen
import adyen_checkout

var cardComponentStyle = Adyen.FormComponentStyle()
cardComponentStyle.mainButtonItem.button.backgroundColor = .black
cardComponentStyle.mainButtonItem.button.title.color = .white
AdyenAppearance.cardComponentStyle = cardComponentStyle
```

### 3DS2 challenge screens

See [3DS2 UI customization](./3DS_CUSTOMIZATION.md).