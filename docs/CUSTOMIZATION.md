## UI Customization


### Android

Follow the Android SDK [customization docs](https://github.com/Adyen/adyen-android/blob/develop/docs/UI_CUSTOMIZATION.md).

### iOS

In **Xcode** create swift class `AdyenAppearance` extending protocol `AdyenComponentAppearanceProvider` or `AdyenDropInAppearanceProvider` depending of your integration.
SDK will use reflection to find the class with this exact name. Our example app contains a [demo implementation](https://github.com/Adyen/adyen-flutter/blob/main/example/ios/Runner/AppDelegate.swift#L22).

Drop-in:

```swift
import Adyen
import adyen_checkout

class AdyenAppearance: AdyenDropInAppearanceProvider {
  static func createDropInStyle() -> Adyen.DropInComponent.Style {
     # provide your custom style here
  }
}
```

Card Component:

```swift
import Adyen
import adyen_checkout

class AdyenAppearance: AdyenComponentAppearanceProvider {
  static func createCardComponentStyle() -> Adyen.FormComponentStyle {
     # provide your custom style here
  }
}
```