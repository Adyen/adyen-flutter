package com.adyen.checkout.flutter.utils

import android.content.Context
import android.util.Log
import android.view.ContextThemeWrapper
import com.adyen.checkout.flutter.R

internal object ThemeUtil {
    /**
     * Components rendered inside a Flutter platform view inherit the theme of the host activity.
     * The Adyen views require a Theme.MaterialComponents descendant, which the host activity theme
     * does not necessarily provide. When it does not, the context is wrapped in
     * [R.style.AdyenCheckout_Flutter] so the components can still be inflated.
     */
    fun applyAdyenTheme(context: Context): Context {
        if (isMaterialTheme(context)) return context

        Log.w(
            Constants.ADYEN_LOG_TAG,
            "The theme of your activity is not a Theme.MaterialComponents descendant, so the " +
                "Adyen theme is applied to the components instead. Let your activity theme extend " +
                "\"AdyenCheckout\" to style the components."
        )
        return ContextThemeWrapper(context, R.style.AdyenCheckout_Flutter)
    }

    private fun isMaterialTheme(context: Context): Boolean {
        val materialThemeAttributes = intArrayOf(com.google.android.material.R.attr.colorPrimaryVariant)
        val typedArray = context.obtainStyledAttributes(materialThemeAttributes)
        return try {
            typedArray.hasValue(0)
        } finally {
            typedArray.recycle()
        }
    }
}
