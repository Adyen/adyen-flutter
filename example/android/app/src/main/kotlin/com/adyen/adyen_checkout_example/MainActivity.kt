package com.adyen.adyen_checkout_example

import io.flutter.embedding.android.FlutterFragmentActivity

//We need to explain to merchants that we require a FlutterFragmentActivity instead the default FlutterActivity in order to support AndroidX. It is required from the checkout SDK.
class MainActivity : FlutterFragmentActivity() {
}
