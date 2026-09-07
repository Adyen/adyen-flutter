# Return URL handling

The `returnUrl` belongs in the `/sessions` or `/payments` request sent by your backend. Configure a
unique URL scheme in the host application and pass the same URL to Adyen.

Flutter 2.0 does not generate return URLs. It forwards incoming native returns to the v6 Checkout
flow. The example app forwards iOS URLs from both `AppDelegate` and `SceneDelegate`:

```swift
Checkout.handleReturn(url: url)
```

On Android, the plugin forwards new intents to the active native checkout controller. The host
activity must inherit from `FlutterFragmentActivity` and declare the URL intent filter required by
the selected return URL.

There can be only one active checkout flow. Returns received after explicit checkout disposal are
ignored.
