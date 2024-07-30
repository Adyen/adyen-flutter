package com.adyen.checkout.flutter.components.view

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.util.AttributeSet
import android.view.View
import android.view.ViewTreeObserver
import android.widget.ScrollView
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.flutter.R
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.round

class DynamicComponentView
    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyle: Int = 0,
    ) : ScrollView(context) {
        private var activity: ComponentActivity? = null
        private var componentFlutterApi: ComponentFlutterInterface? = null
        private var componentId: String = ""
        private val screenDensity = resources.displayMetrics.density
        private var adyenComponentView: AdyenComponentView? = null
        private var job: Job? = null
        private var previousViewportHeight = 0.0

        constructor(
            componentActivity: ComponentActivity,
            componentFlutterApi: ComponentFlutterInterface,
            componentId: String
        ) : this(componentActivity) {
            this.activity = componentActivity
            this.componentFlutterApi = componentFlutterApi
            this.componentId = componentId
        }

        init {
            inflate(getContext(), R.layout.dynamic_component_view, this)
        }

        // Detect input validation errors to trigger Flutter view port height adjustment.
        // Using view lifecycle methods like onMeasure() could break the Flutter rendering.
        private val onLayoutChangeListener =
            View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
                calculateAndResizeViewport()
            }

        fun <T> addComponent(
            component: T,
            activity: ComponentActivity,
        ) where T : ViewableComponent, T : Component {
            val adyenComponentView = findViewById<AdyenComponentView>(R.id.adyen_embedded_component_view)
            adyenComponentView?.getViewTreeObserver()?.addOnGlobalLayoutListener(
                object : ViewTreeObserver.OnGlobalLayoutListener {
                    override fun onGlobalLayout() {
                        // Add listener for input validation error observation
                        adyenComponentView.addOnLayoutChangeListener(onLayoutChangeListener)

                        // Initial viewport adjustment after component loads for the first time
                        calculateAndResizeViewport()
                        adyenComponentView.getViewTreeObserver()?.removeOnGlobalLayoutListener(this)
                    }
                }
            )

            adyenComponentView?.attach(component, activity)
            this.adyenComponentView = adyenComponentView
        }

        fun onDispose() {
            adyenComponentView?.removeOnLayoutChangeListener(onLayoutChangeListener)
            previousViewportHeight = 0.0
            adyenComponentView = null
        }

        private fun calculateAndResizeViewport() {
            job?.cancel()
            job =
                activity?.lifecycleScope?.launch(Dispatchers.Main) {
                    // This delay is necessary to align with the native animations e.g. from pressing pay button to prevent flickering
                    delay(128)
                    val requiredFlutterViewPortHeight = calculateRequiredFlutterViewportHeight()
                    resizeFlutterViewport(requiredFlutterViewPortHeight)
                }
        }

        private fun calculateRequiredFlutterViewportHeight(): Double {
            val componentViewHeight = adyenComponentView?.height ?: 0
            val componentViewHeightScreenDensity = componentViewHeight / screenDensity
            val roundedViewHeight = round(componentViewHeightScreenDensity * 100) / 100
            return roundedViewHeight.toDouble()
        }

        private fun resizeFlutterViewport(viewportHeight: Double) {
            if (viewportHeight == previousViewportHeight) {
                return
            }

            previousViewportHeight = viewportHeight
            componentFlutterApi?.onComponentCommunication(
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESIZE,
                    componentId = componentId,
                    data = viewportHeight
                )
            ) {}
        }
    }
