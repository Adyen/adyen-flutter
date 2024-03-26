package com.adyen.checkout.flutter.utils

class Constants {
    companion object {
        const val WRONG_FLUTTER_ACTIVITY_USAGE_ERROR_MESSAGE =
            "FlutterFragmentActivity not used. Your activity needs to inherit from FlutterFragmentActivity."

        const val GOOGLE_PAY_SESSION_COMPONENT_KEY = "GOOGLE_PAY_SESSION_COMPONENT"
        const val GOOGLE_PAY_ADVANCED_COMPONENT_KEY = "GOOGLE_PAY_ADVANCED_COMPONENT"
        const val GOOGLE_PAY_SESSION_REQUEST_CODE = 486350
        const val GOOGLE_PAY_ADVANCED_REQUEST_CODE = 486351
        const val SDK_PAYMENT_CANCELED_IDENTIFIER = "Payment canceled"
        const val GOOGLE_PAY_ADVANCED_PAYMENT_DATA_KEY = "paymentData"
        const val GOOGLE_PAY_ADVANCED_EXTRA_DATA_KEY = "extraData"
    }
}
