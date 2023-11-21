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
import kotlin.math.round

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

    fun <T> addComponent(cardComponent: T) where T : ViewableComponent, T : Component {
        with(findViewById<AdyenComponentView>(R.id.adyen_component_view)) {
            attach(cardComponent, activity)
            addComponentHeightObserver()
        }
    }

    private fun addComponentHeightObserver() {
        ComponentHeightMessenger.instance().observe(activity) {
            activity.lifecycleScope.launch {
                //We need to wait for animation to finish e.g. when scheme icons disappear
                delay(300)
                updateComponentViewHeight()
            }
        }
    }

    private fun updateComponentViewHeight() {
        val cardViewHeight = findViewById<FrameLayout>(R.id.frameLayout_componentContainer)?.getChildAt(0)?.height
        if (cardViewHeight == null) {
            activity.lifecycleScope.launch() {
                //View not rendered therefore we try again after delay.
                //This is a workaround because there is currently no notifier from the native view.
                delay(100)
                updateComponentViewHeight()
            }
            return
        }

        val standardMargin = resources.getDimension(R.dimen.standard_margin)
        val buttonHeight = (findViewById<MaterialButton>(R.id.payButton)?.height ?: 0).plus((standardMargin))
        val componentHeight = ((cardViewHeight + buttonHeight) / screenDensity).toDouble()
        val roundedHeight = round(componentHeight * 100) / 100
        componentFlutterApi.onComponentCommunication(
            ComponentCommunicationModel(type = ComponentCommunicationType.RESIZE, data = roundedHeight)
        ) {}
    }
}
