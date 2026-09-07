# UI customization

Checkout 2.0 alpha uses the native v6 default theme. Checkout theming and granular 3DS2 appearance
configuration are intentionally deferred until the native APIs expose an aligned public contract.

## Android

The generic native payment component is rendered inside a Flutter platform view. Use a
`FlutterFragmentActivity` host and keep the Flutter `NormalTheme` compatible with the native Checkout
UI:

```xml
<style name="NormalTheme" parent="Theme.MaterialComponents.DayNight.NoActionBar">
    <item name="android:windowBackground">?android:colorBackground</item>
</style>
```

Payment-method field options are configured through the allowlisted Dart models, such as
`CardConfiguration`.

## iOS

Native v6 UI uses its default `CheckoutTheme`. Configure the payment component through the
allowlisted Dart configuration models. No CocoaPods integration is required; the plugin uses Swift
Package Manager.
