package com.adyen.checkout.flutter.components.view

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.util.AttributeSet
import android.view.ViewTreeObserver
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.internal.ButtonComponent
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.flutter.R
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.button.MaterialButton
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.launch

class DynamicComponentView
    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyle: Int = 0,
    ) : ConstraintLayout(context) {
        private val screenDensity = resources.displayMetrics.density
        private val standardMargin = resources.getDimension(com.adyen.checkout.ui.core.R.dimen.standard_margin)
        private val layoutChangeFlow = MutableStateFlow<Int?>(null)
        private var activity: ComponentActivity? = null
        private var componentFlutterApi: ComponentFlutterInterface? = null
        private var componentId: String = ""
        private var adyenComponentView: AdyenComponentView? = null
        private var ignoreLayoutChanges = false
        private val onLayoutChangeListener =
            OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
                // Used to detect input validation errors to trigger Flutter viewport height adjustment.
                if (!ignoreLayoutChanges) {
                    layoutChangeFlow.tryEmit(v.height)
                }
            }

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

        override fun onMeasure(
            widthMeasureSpec: Int,
            heightMeasureSpec: Int
        ) {
            val heightSize = MeasureSpec.getSize(heightMeasureSpec)
            super.onMeasure(widthMeasureSpec, heightSize)
        }

        fun <T> addComponent(
            component: T,
            activity: ComponentActivity,
        ) where T : Component, T : ViewableComponent {
            val adyenComponentView = findViewById<AdyenComponentView>(R.id.adyen_embedded_component_view)
            adyenComponentView?.getViewTreeObserver()
                ?.addOnGlobalLayoutListener(
                    object : ViewTreeObserver.OnGlobalLayoutListener {
                        override fun onGlobalLayout() {
                            if (component is CardComponent) {
                                overrideSubmit(component)
                            }

                            // Set the initial viewport height after view appears
                            resizeFlutterViewport(calculateFlutterViewportHeight())
                            adyenComponentView.getViewTreeObserver()?.removeOnGlobalLayoutListener(this)
                        }
                    }
                )

            adyenComponentView?.attach(component, activity)
            adyenComponentView?.addOnLayoutChangeListener(onLayoutChangeListener)
            onLayoutChangeFlow(activity)
            this.adyenComponentView = adyenComponentView
        }

        fun onDispose() {
            adyenComponentView?.removeOnLayoutChangeListener(onLayoutChangeListener)
            adyenComponentView = null
            activity = null
            componentFlutterApi = null
            ignoreLayoutChanges = false
        }

        private fun overrideSubmit(component: ButtonComponent) {
            val payButton = findViewById<MaterialButton>(com.adyen.checkout.ui.core.R.id.payButton)
            payButton?.setOnClickListener {
                activity?.lifecycleScope?.launch {
                    // Ignore layout changes while the pay button animates and renders possible input errors.
                    ignoreLayoutChanges = true
                    component.submit()
                    // Wait until possible input errors are rendered and then trigger viewport calculation.
                    delay(500)
                    resizeFlutterViewport(calculateFlutterViewportHeight())
                    // Wait until resizing is done to activate layout change based resizing again.
                    delay(500)
                    ignoreLayoutChanges = false
                }
            }
        }

        @OptIn(FlowPreview::class)
        private fun onLayoutChangeFlow(activity: ComponentActivity) {
            activity.lifecycleScope.launch {
                // Debounce to prevent too many redraws.
                layoutChangeFlow.debounce(300).collect { value ->
                    value?.let {
                        resizeFlutterViewport(calculateFlutterViewportHeight())
                    }
                }
            }
        }

        private fun calculateFlutterViewportHeight(): Int {
            val componentViewHeight = adyenComponentView?.measuredHeight ?: 0
            val componentViewHeightScreenDensity = componentViewHeight / screenDensity
            return componentViewHeightScreenDensity.toInt()
        }

        private fun resizeFlutterViewport(viewportHeight: Int) {
            val standardMarginScreenDensity = standardMargin / screenDensity
            componentFlutterApi?.onComponentCommunication(
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESIZE,
                    componentId = componentId,
                    data = (viewportHeight + standardMarginScreenDensity).toDouble()
                )
            ) {}
        }
    }
