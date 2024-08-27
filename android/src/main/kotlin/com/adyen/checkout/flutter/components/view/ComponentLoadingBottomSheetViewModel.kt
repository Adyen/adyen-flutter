package com.adyen.checkout.flutter.components.view

import androidx.lifecycle.ViewModel
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent

class ComponentLoadingBottomSheetViewModel<T> : ViewModel() where T : Component, T : ViewableComponent {
    var component: T? = null

    fun reset() {
        component = null
    }
}
