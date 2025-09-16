package com.adyen.checkout.flutter.components.view

import android.content.Context
import android.util.AttributeSet
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.appcompat.widget.SwitchCompat
import androidx.core.content.ContextCompat
import androidx.core.view.children
import androidx.core.view.postDelayed
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.components.core.internal.Component
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.ui.core.old.AdyenComponentView
import com.adyen.checkout.ui.core.old.internal.ui.ViewableComponent
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
        private var activity: ComponentActivity? = null
        private var componentFlutterApi: ComponentFlutterInterface? = null
        private var componentId: String = ""
        private var ignoreLayoutChanges = false
        private var interactionBlocked = false

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
            val adyenComponentView =
                AdyenComponentView(context).apply {
                    onComponentViewGlobalLayout(this, component)
                    attach(component, activity)
                }

            addView(adyenComponentView)
        }

        fun onDispose() {
            activity = null
            componentFlutterApi = null
            ignoreLayoutChanges = false
            interactionBlocked = false
        }

        private fun <T> onComponentViewGlobalLayout(
            adyenComponentView: AdyenComponentView,
            component: T
        ) where T : Component, T : ViewableComponent {
            adyenComponentView.getViewTreeObserver()?.addOnGlobalLayoutListener(
                object : ViewTreeObserver.OnGlobalLayoutListener {
                    override fun onGlobalLayout() {
                        if (component is CardComponent) {
                            overrideSubmit(component)
                        }

                        adyenComponentView.getViewTreeObserver()?.removeOnGlobalLayoutListener(this)
                    }
                }
            )
        }

        private fun overrideSubmit(component: CardComponent) {
            val payButton = findViewById<MaterialButton>(com.adyen.checkout.ui.core.R.id.payButton)
            if (android.os.Build.VERSION.SDK_INT <= android.os.Build.VERSION_CODES.O) {
                disableRippleAnimationOnPayButton()
                disableRippleAnimationOnStorePaymentMethodSwitch()
            }

            payButton?.setOnClickListener {
                isHintAnimationEnabledOnTextInputFields(this, false)
                ignoreLayoutChanges = true
                if (!interactionBlocked) {
                    interactionBlocked = true
                    component.submit()
                }
                resetInteractionBlocked()
                postDelayed(100) {
                    resizeFlutterViewport(calculateFlutterViewportHeight())
                }
                postDelayed(500) {
                    ignoreLayoutChanges = false
                    isHintAnimationEnabledOnTextInputFields(this, true)
                }
            }
        }

        // This is necessary because the RippleAnimation leads to an crash on older Android devices: https://github.com/Adyen/adyen-flutter/issues/335
        private fun disableRippleAnimationOnPayButton() {
            findViewById<MaterialButton>(com.adyen.checkout.ui.core.R.id.payButton)?.let { payButton ->
                payButton.backgroundTintList = null
                payButton.background =
                    ContextCompat.getDrawable(
                        context,
                        com.adyen.checkout.flutter.R.drawable.adyen_legacy_pay_button_background
                    )
            }

            findViewById<FrameLayout>(
                com.adyen.checkout.ui.core.R.id.frameLayout_buttonContainer
            )?.let { buttonContainer ->
                val standardQuarterMargin =
                    resources.getDimension(com.adyen.checkout.ui.core.R.dimen.standard_quarter_margin).toInt()
                buttonContainer.setPadding(0, standardQuarterMargin, 0, standardQuarterMargin)
            }
        }

        // This is necessary because the RippleAnimation leads to an crash on older Android devices: https://github.com/Adyen/adyen-flutter/issues/335
        private fun disableRippleAnimationOnStorePaymentMethodSwitch() {
            findViewById<SwitchCompat>(com.adyen.checkout.card.R.id.switch_storePaymentMethod)?.let { switch ->
                switch.backgroundTintList = null
                switch.background =
                    ContextCompat.getDrawable(
                        context,
                        com.adyen.checkout.flutter.R.drawable.adyen_legacy_switch_background
                    )
            }
        }

        private fun calculateFlutterViewportHeight(): Int {
            val componentViewHeightScreenDensity = measuredHeight / screenDensity
            return componentViewHeightScreenDensity.toInt()
        }

        private fun resizeFlutterViewport(viewportHeight: Int) {
            componentFlutterApi?.onComponentCommunication(
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESIZE,
                    componentId = componentId,
                    data = viewportHeight
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

        // TODO - We can use cardComponent.setInteractionBlocked() when the fix for releasing the blocked interaction is available in then native SDK
        private fun resetInteractionBlocked() {
            postDelayed(1000) {
                interactionBlocked = false
            }
        }
    }
