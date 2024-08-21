package com.adyen.checkout.flutter.components.view

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterInterface
import android.content.Context
import android.util.AttributeSet
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.core.view.children
import androidx.core.view.postDelayed
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.ui.core.AdyenComponentView
import com.adyen.checkout.ui.core.internal.ui.ViewableComponent
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputLayout

class DynamicComponentView
    @JvmOverloads
    constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyle: Int = 0,
    ) : FrameLayout(context) {
        private val screenDensity = resources.displayMetrics.density
        private val adyenComponentView: AdyenComponentView = AdyenComponentView(context)
        private var activity: ComponentActivity? = null
        private var componentFlutterApi: ComponentFlutterInterface? = null
        private var componentId: String = ""
        private var ignoreLayoutChanges = false
        private var isPaymentInProgress = false

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
            payButton?.setOnClickListener {
                isHintAnimationEnabledOnTextInputFields(this, false)
                ignoreLayoutChanges = true
                if (!isPaymentInProgress) {
                    isPaymentInProgress = true
                    component.submit()
                }
                postDelayed(100) {
                    resizeFlutterViewport(calculateFlutterViewportHeight())
                }
                postDelayed(500) {
                    ignoreLayoutChanges = false
                    isHintAnimationEnabledOnTextInputFields(this, true)
                    isPaymentInProgress = false
                }
            }
        }

        fun onDispose() {
            activity = null
            componentFlutterApi = null
            ignoreLayoutChanges = false
            isPaymentInProgress = false
        }

        private fun calculateFlutterViewportHeight(): Float {
            val componentViewHeightScreenDensity = measuredHeight / screenDensity
            return componentViewHeightScreenDensity
        }

        private fun resizeFlutterViewport(viewportHeight: Float) {
            componentFlutterApi?.onComponentCommunication(
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESIZE,
                    componentId = componentId,
                    data = viewportHeight.toDouble()
                )
            ) {}
        }

        private fun isHintAnimationEnabledOnTextInputFields(
            viewGroup: ViewGroup,
            enabled: Boolean
        ) {
            viewGroup.children.forEach { child ->
                when (child) {
                    is TextInputLayout -> child.isHintAnimationEnabled = enabled
                    !is ViewGroup -> Unit
                    else -> isHintAnimationEnabledOnTextInputFields(child, enabled)
                }
            }
        }
    }
