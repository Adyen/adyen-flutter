package com.adyen.checkout.flutter.components.view

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.util.AttributeSet
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.lifecycle.viewModelScope
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputLayout
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class DynamicComponentView
    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyle: Int = 0,
    ) : FrameLayout(context) {
        private val screenDensity = resources.displayMetrics.density
        private val standardMargin = resources.getDimension(com.adyen.checkout.ui.core.R.dimen.standard_margin)
        private var activity: ComponentActivity? = null
        private var componentFlutterApi: ComponentFlutterInterface? = null
        private var componentId: String = ""
        private var adyenComponentView: AdyenComponentView = AdyenComponentView(context)
        private var ignoreLayoutChanges = false

        constructor(
            componentActivity: ComponentActivity,
            componentFlutterApi: ComponentFlutterInterface,
            componentId: String
        ) : this(componentActivity) {
            this.activity = componentActivity
            this.componentFlutterApi = componentFlutterApi
            this.componentId = componentId
        }

        // Usage of complete component height also when having error hints
        override fun onMeasure(
            widthMeasureSpec: Int,
            heightMeasureSpec: Int
        ) {
            val heightSize = MeasureSpec.getSize(heightMeasureSpec)
            super.onMeasure(widthMeasureSpec, heightSize)
        }

        override fun onLayout(
            changed: Boolean,
            l: Int,
            t: Int,
            r: Int,
            b: Int
        ) {
            super.onLayout(changed, l, t, r, b)

            if (changed && !ignoreLayoutChanges) {
                resizeFlutterViewport(calculateFlutterViewportHeight())
            }
        }

        fun <T> addComponent(
            component: T,
            activity: ComponentActivity,
        ) where T : Component, T : ViewableComponent {
            adyenComponentView.getViewTreeObserver()
                ?.addOnGlobalLayoutListener(
                    object : ViewTreeObserver.OnGlobalLayoutListener {
                        override fun onGlobalLayout() {
                            if (component is CardComponent) {
                                overrideSubmit(component)
                            }

                            adyenComponentView.getViewTreeObserver()?.removeOnGlobalLayoutListener(this)
                        }
                    }
                )

            adyenComponentView.attach(component, activity)
            addView(adyenComponentView)
        }

        private fun overrideSubmit(component: CardComponent) {
            val payButton = findViewById<MaterialButton>(com.adyen.checkout.ui.core.R.id.payButton)
            val cardInputField =
                findViewById<TextInputLayout>(com.adyen.checkout.card.R.id.textInputLayout_cardNumber)
            payButton?.setOnClickListener {
                component.viewModelScope.launch {
                    // Ignore layout changes while the pay button animates and renders possible input errors.
                    ignoreLayoutChanges = true
                    cardInputField?.isHintAnimationEnabled = false
                    component.submit()
                    delay(400)
                    resizeFlutterViewport(calculateFlutterViewportHeight())
                    ignoreLayoutChanges = false
                    cardInputField?.isHintAnimationEnabled = true
                }
            }
        }

        fun onDispose() {
            activity = null
            componentFlutterApi = null
            ignoreLayoutChanges = false
        }

        private fun calculateFlutterViewportHeight(): Float {
            val componentViewHeightScreenDensity = measuredHeight / screenDensity
            return componentViewHeightScreenDensity
        }

        private fun resizeFlutterViewport(viewportHeight: Float) {
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
