## UI Customization


### Android

Follow the Android SDK [customization docs](https://github.com/Adyen/adyen-android/blob/develop/docs/UI_CUSTOMIZATION.md).

### iOS

In your swift layer e.g. within the AppDelegate, set the `dropInStyle` or the `cardComponentStyle` of AdyenAppearance depending on your integration.
The SDK will use your provided style and apply it automatically. Feel free to check out the example app [implementation](https://github.com/Adyen/adyen-flutter/blob/main/example/ios/Runner/AppDelegate.swift#L23).

Drop-in:

```swift
import Adyen
import adyen_checkout

var dropInStyle = Adyen.DropInComponent.Style()
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