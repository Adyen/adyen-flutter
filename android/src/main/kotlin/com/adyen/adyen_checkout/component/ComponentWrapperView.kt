package com.adyen.adyen_checkout.component

import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import android.content.Context
import android.util.AttributeSet
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.doOnPreDraw
import com.adyen.adyen_checkout.R
import com.adyen.checkout.ui.core.AdyenComponentView
import com.google.android.material.button.MaterialButton


class ComponentWrapperView(
    context: Context,
    private val componentFlutterApi: ComponentFlutterApi,
    attrs: AttributeSet? = null,
) :
    ConstraintLayout(context, attrs) {

    private val screenDensity = context.resources.displayMetrics.density

    init {
        initView()
    }

    private fun initView() {
        inflate(context, R.layout.component_wrapper_view, this)
        val adyenComponentView = findViewById<AdyenComponentView>(R.id.adyen_component_view)

        adyenComponentView.doOnPreDraw {
            val param = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
            adyenComponentView.layoutParams = param

            //Container
            var container = findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
            val containerParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
            container.layoutParams = containerParams

            //Button container
            var buttonContainer = findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
            val buttonContainerParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
            buttonContainer.layoutParams = buttonContainerParams

            //Button
            var button = findViewById<FrameLayout>(R.id.frameLayout_buttonContainer).getChildAt(0)
            val buttonParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            )
            button.layoutParams = buttonParams

            // CARD
            var card = findViewById<FrameLayout>(R.id.frameLayout_componentContainer).getChildAt(0) as ViewGroup
            var layoutparams = card.layoutParams
            layoutparams.height = LinearLayout.LayoutParams.WRAP_CONTENT
            card.layoutParams = layoutparams
        }
    }


    fun addCard(cardComponent: com.adyen.checkout.card.CardComponent, activity: ComponentActivity) {
        val adyenComponentView = findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.attach(cardComponent, activity)



        addOnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
            println("bottom: $bottom")
            println("old-bottom: $oldBottom")
            val cardViewHeight = findViewById<FrameLayout>(R.id.frameLayout_componentContainer).getChildAt(0).height
            val buttonHeight = findViewById<MaterialButton>(R.id.payButton).height + (16 * screenDensity)
            val componentHeight = (cardViewHeight + buttonHeight) / screenDensity
            componentFlutterApi.onComponentCommunication(
                ComponentCommunicationModel(type = ComponentCommunicationType.RESIZE, data = componentHeight)
            ) {}
        }
    }
}
