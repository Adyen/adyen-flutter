package com.adyen.adyen_checkout.component

import CheckoutFlutterApi
import ComponentCommunicationModel
import ComponentCommunicationType
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.children
import androidx.core.view.doOnPreDraw
import com.adyen.adyen_checkout.R
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.core.Environment
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject
import java.util.Locale

internal class CardComponent(
    private val activity: ComponentActivity,
    private val checkoutFlutterApi: CheckoutFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView {
    private val componentView: AdyenComponentView

    private val componentWrapperView: ComponentWrapperView
    override fun getView(): View {
        return componentWrapperView
    }

    val paymentMethods = creationParams?.get("paymentMethods") as String
    val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))

    val clientKey = creationParams?.get("clientKey") as String
    val cardConfiguration =
        CardConfiguration.Builder(Locale("nl", "NL"), Environment.TEST, clientKey)
            .setHolderNameRequired(true)
            .build()

    val schemes = paymentMethodsApiResponse.paymentMethods?.filter { it.type == "scheme" }
    var cardComponent: CardComponent


    override fun dispose() {
        Log.d(
            "AdyenCheckout",
            "DISPOSE VIEW"
        )
        cardComponent.delegate.onCleared()
        componentView.invalidate()
    }

    init {
        cardComponent = CardComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = schemes!!.first(),
            configuration = cardConfiguration,
            callback = CardCallback(checkoutFlutterApi),
            key = System.currentTimeMillis().toString()
        )

        cardComponent.delegate
        componentView = AdyenComponentView(context)
        componentView.attach(cardComponent, activity)
        componentWrapperView = ComponentWrapperView(activity, componentView)
        val density = context.resources.displayMetrics.density
        var sum = 0.0

        componentView.doOnPreDraw {
            println("pre draw")
            val card =
                componentView.findViewById<FrameLayout>(R.id.frameLayout_componentContainer).getChildAt(0) as ViewGroup
            val layoutparams = card.layoutParams
            layoutparams.height = LinearLayout.LayoutParams.WRAP_CONTENT
            card.layoutParams = layoutparams
            card.children.forEach {
                println(it.height)
                sum += it.height
            }

            val payButton = componentView.findViewById<View>(R.id.frameLayout_buttonContainer).height
            sum += payButton
            println("sum is: $sum")
            checkoutFlutterApi.onComponentCommunication(
                ComponentCommunicationModel(
                    type = ComponentCommunicationType.RESIZE,
                    data = (componentView.height / density)
                ),
                callback = {},
            )
        }
    }
}

class CardComponentFactory(
    private val activity: ComponentActivity,
    private val checkoutFlutterApi: CheckoutFlutterApi,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return CardComponent(activity, checkoutFlutterApi, context, viewId, creationParams)
    }
}

class CardCallback(private val checkoutFlutterApi: CheckoutFlutterApi) : ComponentCallback<CardComponentState> {
    override fun onSubmit(state: CardComponentState) {
        Log.d(
            "AdyenCheckout",
            state.toString()
        )

        val paymentComponentJson =
            PaymentComponentData.SERIALIZER.serialize(state.data)
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.PAYMENTCOMPONENT,
            data = paymentComponentJson.toString(),
        )
        checkoutFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
    }

    override fun onError(componentError: ComponentError) {
    }


}
