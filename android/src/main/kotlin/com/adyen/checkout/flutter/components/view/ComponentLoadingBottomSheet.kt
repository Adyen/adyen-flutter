package com.adyen.checkout.flutter.components.view

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.FragmentManager
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.flutter.R
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.bottomsheet.BottomSheetDialogFragment

internal class ComponentLoadingBottomSheet<T> : BottomSheetDialogFragment() where T : ViewableComponent, T : Component {
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? = inflater.inflate(R.layout.component_bottom_sheet_content, container, false)

    @Suppress("UNCHECKED_CAST")
    override fun onViewCreated(
        view: View,
        savedInstanceState: Bundle?
    ) {
        // We need to cast the component because it has two types T (ViewableComponent and Component)
        (component as? T)?.let {
            view.findViewById<AdyenComponentView>(R.id.adyen_component_view)?.attach(it, viewLifecycleOwner)
            isCancelable = false
        }
    }

    override fun onCreateDialog(savedInstanceState: Bundle?) =
        super.onCreateDialog(savedInstanceState).apply {
            window?.setWindowAnimations(
                com.adyen.checkout.ui.core.R.style.AdyenCheckout_BottomSheet_NoWindowEnterDialogAnimation
            )
        }

    companion object {
        private const val TAG = "AdyenComponentLoadingBottomSheet"
        private var component: Any? = null

        fun <T> show(
            fragmentManager: FragmentManager,
            component: T
        ) where T : ViewableComponent, T : Component {
            this.component = component
            ComponentLoadingBottomSheet<T>().show(fragmentManager, TAG)
        }

        fun hide(fragmentManager: FragmentManager) {
            component = null
            fragmentManager.findFragmentByTag(TAG)?.let {
                (it as? BottomSheetDialogFragment)?.dismiss()
            }
        }

        fun isVisible(fragmentManager: FragmentManager): Boolean = fragmentManager.findFragmentByTag(TAG) != null
    }
}
