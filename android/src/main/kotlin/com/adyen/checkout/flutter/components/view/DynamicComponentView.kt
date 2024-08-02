package com.adyen.checkout.flutter.components.view

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.util.AttributeSet
import android.view.SurfaceHolder
import android.view.View
import android.view.ViewTreeObserver
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.lifecycle.lifecycleScope
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
@JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0,
) : ConstraintLayout(context) {
    private var activity: ComponentActivity? = null
    private var componentFlutterApi: ComponentFlutterInterface? = null
    private var componentId: String = ""
    private val screenDensity = resources.displayMetrics.density
    private val standardMargin = resources.getDimension(com.adyen.checkout.ui.core.R.dimen.standard_margin)
    private var adyenComponentView: AdyenComponentView? = null
    private val layoutChangeFlow = MutableStateFlow<Int?>(null)
    private var ignoreLayoutChanges = false

    // Detect input validation errors to trigger Flutter view port height adjustment.
    // Using view lifecycle methods like onMeasure() could break the Flutter rendering.
    private val onLayoutChangeListener = View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
        if (!ignoreLayoutChanges) {
            calculateNewFlutterViewportHeightAndEmit()
        }
    }

    constructor(
        componentActivity: ComponentActivity, componentFlutterApi: ComponentFlutterInterface, componentId: String
    ) : this(componentActivity) {
        this.activity = componentActivity
        this.componentFlutterApi = componentFlutterApi
        this.componentId = componentId
    }

    init {
        inflate(getContext(), R.layout.dynamic_component_view, this)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val heightSize = MeasureSpec.getSize(heightMeasureSpec)
        super.onMeasure(widthMeasureSpec, heightSize)
        if (!ignoreLayoutChanges) {
            calculateNewFlutterViewportHeightAndEmit()
        }
    }

    fun <T> addComponent(
        component: T,
        activity: ComponentActivity,
    ) where T : Component, T : ViewableComponent {
        val adyenComponentView = findViewById<AdyenComponentView>(R.id.adyen_embedded_component_view)
        adyenComponentView?.getViewTreeObserver()
            ?.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
                override fun onGlobalLayout() {
                    if (component is ButtonComponent) {
                        overrideSubmit(component)
                    }
                    // Add listener for input validation error observation.
                    adyenComponentView.addOnLayoutChangeListener(onLayoutChangeListener)
                    adyenComponentView.getViewTreeObserver()?.removeOnGlobalLayoutListener(this)
                }
            })

        adyenComponentView?.attach(component, activity)
        subscribeLayoutChangeFlow(activity)
        this.adyenComponentView = adyenComponentView
    }

    private fun calculateNewFlutterViewportHeightAndEmit() {
        val requiredFlutterViewPortHeight = calculateRequiredFlutterViewportHeight()
        layoutChangeFlow.tryEmit(requiredFlutterViewPortHeight)
    }

    private fun overrideSubmit(component: ButtonComponent) {
        findViewById<MaterialButton>(com.adyen.checkout.ui.core.R.id.payButton)?.setOnClickListener {
            //Ignore layout changes while the pay button animates and renders possible input errors
            ignoreLayoutChanges = true
            component.submit()
            delayAndResizeFlutterViewport()
        }
    }

    private fun delayAndResizeFlutterViewport() {
        activity?.lifecycleScope?.launch {
            //Wait until hint is being moved to border to prevent flickering. Resize Flutter viewport manually because layout changes are ignored.
            delay(250)
            val requiredFlutterViewPortHeight = calculateRequiredFlutterViewportHeight()
            resizeFlutterViewport(requiredFlutterViewPortHeight)
            delay(1000)
            ignoreLayoutChanges = false
        }
    }

    fun onDispose() {
        adyenComponentView?.removeOnLayoutChangeListener(onLayoutChangeListener)
        adyenComponentView = null
    }

    @OptIn(FlowPreview::class)
    private fun subscribeLayoutChangeFlow(activity: ComponentActivity) {
        activity.lifecycleScope.launch {
            //Debounce require at least 100 milliseconds to prevent to many redraws
            layoutChangeFlow.debounce(100).collect { viewPortHeight ->
                if (viewPortHeight != null) {
                    resizeFlutterViewport(viewPortHeight)
                }
            }
        }
    }

    private fun calculateRequiredFlutterViewportHeight(): Int {
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
