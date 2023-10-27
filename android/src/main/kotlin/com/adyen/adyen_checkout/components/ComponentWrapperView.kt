package com.adyen.adyen_checkout.components

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.R
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch


class ComponentWrapperView
@JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : ConstraintLayout(context, attrs, defStyleAttr) {
    constructor(activity: ComponentActivity, componentFlutterApi: ComponentFlutterApi) : this(context = activity) {
        this.activity = activity
        this.componentFlutterApi = componentFlutterApi
    }

    private lateinit var activity: ComponentActivity
    private lateinit var componentFlutterApi: ComponentFlutterApi
    private val screenDensity = context.resources.displayMetrics.density

    init {
        inflate(context, R.layout.component_wrapper_view, this)
    }

    @Suppress("UNUSED_ANONYMOUS_PARAMETER")
    fun <T> addComponent(cardComponent: T) where T : ViewableComponent, T : Component {
        with(findViewById<AdyenComponentView>(R.id.adyen_component_view)) {
            attach(cardComponent, activity)
        }

        // We delay adding the change listener to prevent initial layout change coverage
        activity.lifecycleScope.launch {
            delay(500)
            addOnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
                println("layout change listener")
                updateComponentViewHeight()
            }
        }
    }

    private fun updateComponentViewHeight() {
        val valueInPixels = resources.getDimension(R.dimen.standard_margin)
        val cardViewHeight = findViewById<FrameLayout>(R.id.frameLayout_componentContainer).getChildAt(0).height
        val buttonHeight = findViewById<MaterialButton>(R.id.payButton).height + (valueInPixels)
        val componentHeight = ((cardViewHeight + buttonHeight) / screenDensity).toDouble()
        componentFlutterApi.onComponentCommunication(
            ComponentCommunicationModel(type = ComponentCommunicationType.RESIZE, data = componentHeight)
        ) {}
    }

}
