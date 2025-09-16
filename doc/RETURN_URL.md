# Setting up the returnUrl

The `returnUrl` is a **mandatory** configuration for handling payment redirections, such as 3DS2 web
challenges or other redirect-based payment methods. It specifies the URL where the shopper should be
redirected back to your app after completing an action. This URL must be **provided as a parameter
in your `/sessions` or `/payments` request**.

**Important considerations:**

* When using the `/sessions` flow, you need to know the platform (Android or iOS) and the
  integration type (Drop-in or Components) upfront to correctly configure the `returnUrl`.
* The maximum length for a `returnUrl` is **1024 characters**.

## For Android:

For Android, the returnUrl structure and prerequisites differ based on whether you are using the
**Drop-in** or **Components** integration.

### Android Drop-in

When using the Drop-in solution, the returnUrl is **predefined**.

* **Format:** `adyencheckout://` scheme, followed by your **package name**.
* **Example:** `adyencheckout://com.adyen.adyen_checkout_example`.

The `AdyenCheckout.instance.getReturnUrl()` method is available to provide this string value. You
can also provide the string as a hardcoded constant.

### Android Components

For Components integration on Android, you need to define a **custom intent filter**.

* **Format:** `adyencheckout://` scheme, followed by your **package name**.
* **Path:** You **must add a path**.
* **Example:** `adyencheckout://com.adyen.adyen_checkout_example/adyenPayment`.

**Prerequisites for Android Components:**

* **Add a [custom intent](https://github.com/Adyen/adyen-flutter/blob/main/example/android/app/src/main/AndroidManifest.xml#L29) filter** to your `Manifest.xml` file.
* A custom scheme is not yet supported for Android Components.

## For iOS:

For iOS, the returnUrl setup is **consistent for both Drop-in and Components** integrations.

* **Format:** You need to **define a unique custom URL scheme** for your app.
* **Example:** `com.mydomain.adyencheckout://`.

**Prerequisites for iOS:**

* **Add the [return URL handler](https://github.com/Adyen/adyen-flutter/blob/main/example/ios/Runner/AppDelegate.swift#L18)** to your `AppDelegate` in your native iOS layer.
* **Add the [custom URL scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)** that matches your returnUrl to your `Info.plist` file.
