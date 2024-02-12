package com.adyen.checkout.flutter.components

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.flutter.R
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.bottomsheet.BottomSheetDialogFragment

class ComponentLoadingBottomSheet<T>(private val component: T) :
    BottomSheetDialogFragment() where T : ViewableComponent, T : Component {
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? = inflater.inflate(R.layout.component_bottom_sheet_content, container, false)

    override fun onViewCreated(
        view: View,
        savedInstanceState: Bundle?
    ) {
        view.findViewById<AdyenComponentView>(R.id.adyen_component_view)?.attach(component, viewLifecycleOwner)
    }

    companion object {
        const val TAG = "AdyenComponentLoadingBottomSheet"
    }
}
