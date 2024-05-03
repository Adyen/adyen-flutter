package com.adyen.checkout.flutter.utils

class Constants {
    companion object {
        const val WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE =
            "FlutterFragmentActivity not used. Your activity needs to inherit from FlutterFragmentActivity."

        const val GOOGLE_PAY_SESSION_COMPONENT_KEY = "GOOGLE_PAY_SESSION_COMPONENT"
        const val GOOGLE_PAY_ADVANCED_COMPONENT_KEY = "GOOGLE_PAY_ADVANCED_COMPONENT"
        const val INSTANT_SESSION_COMPONENT_KEY = "INSTANT_SESSION_COMPONENT"
        const val INSTANT_ADVANCED_COMPONENT_KEY = "INSTANT_ADVANCED_COMPONENT"
        const val GOOGLE_PAY_COMPONENT_REQUEST_CODE = 486351
        const val SDK_PAYMENT_CANCELED_IDENTIFIER = "Payment canceled"
        const val ADVANCED_PAYMENT_DATA_KEY = "data"
        const val ADVANCED_EXTRA_DATA_KEY = "extra"
    }
}
