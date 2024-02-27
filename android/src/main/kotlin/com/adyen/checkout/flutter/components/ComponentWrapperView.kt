package com.adyen.checkout.flutter.components

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.flutter.R
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.round

class ComponentWrapperView
    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyleAttr: Int = 0
    ) : ConstraintLayout(context, attrs, defStyleAttr) {
        constructor(
            activity: ComponentActivity,
            componentFlutterApi: ComponentFlutterInterface
        ) : this(context = activity) {
            this.activity = activity
            this.componentFlutterApi = componentFlutterApi
        }

        private lateinit var activity: ComponentActivity
        private lateinit var componentFlutterApi: ComponentFlutterInterface
        private val screenDensity = context.resources.displayMetrics.density

        init {
            inflate(context, R.layout.component_wrapper_view, this)
        }

        fun <T> addComponent(
            component: T,
            componentId: String
        ) where T : ViewableComponent, T : Component {
            with(findViewById<AdyenComponentView>(R.id.adyen_component_view)) {
                attach(component, activity)
                addComponentHeightObserver(componentId)
            }
        }

        private fun addComponentHeightObserver(componentId: String) {
            ComponentHeightMessenger.instance().removeObservers(activity)
            ComponentHeightMessenger.instance().observe(activity) {
                activity.lifecycleScope.launch {
                    // We need to wait for animation to finish e.g. when scheme icons disappear
                    delay(300)
                    updateComponentViewHeight(componentId)
                }
            }
        }

        private fun updateComponentViewHeight(componentId: String) {
            val cardViewHeight = findViewById<FrameLayout>(R.id.frameLayout_componentContainer)?.getChildAt(0)?.height
            if (cardViewHeight == null) {
                activity.lifecycleScope.launch {
                    // View not rendered therefore we try again after delay.
                    // This is a workaround because there is currently no notifier from the native view.
                    delay(100)
                    updateComponentViewHeight(componentId)
                }
                return
            }

            val standardMargin = resources.getDimension(R.dimen.standard_margin)
            val buttonHeight = (findViewById<MaterialButton>(R.id.payButton)?.height ?: 0).plus((standardMargin))
            val componentHeight = ((cardViewHeight + buttonHeight) / screenDensity).toDouble()
            val roundedHeight = round(componentHeight * 100) / 100
            componentFlutterApi.onComponentCommunication(
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESIZE,
                    componentId = componentId,
                    data = roundedHeight
                )
            ) {}
        }
    }
