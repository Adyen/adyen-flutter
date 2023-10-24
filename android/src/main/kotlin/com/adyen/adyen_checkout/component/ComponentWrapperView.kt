package com.adyen.adyen_checkout.component

import android.content.Context
import android.util.AttributeSet
import android.widget.LinearLayout
import com.adyen.checkout.ui.core.AdyenComponentView

class ComponentWrapperView(
    context: Context,
    child: AdyenComponentView,
    attrs: AttributeSet? = null,
) :
    LinearLayout(context, attrs) {
    init {
        orientation = VERTICAL
        layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        addView(child)
    }
}
