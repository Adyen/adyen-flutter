package com.adyen.adyen_checkout.component

import CheckoutFlutterApi
import PlatformCommunicationModel
import PlatformCommunicationType
import android.content.Context
import android.util.Log
import android.view.View
import androidx.activity.ComponentActivity
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
    activity: ComponentActivity,
    cardCallback: CardCallback,
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView {
    private val componentView: AdyenComponentView
    override fun getView(): View {
        return componentView
    }

    val paymentMethods = creationParams?.get("paymentMethods") as String
    val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))

    val clientKey = creationParams?.get("clientKey") as String
    val cardConfiguration =
        CardConfiguration.Builder(Locale("nl", "NL"), Environment.TEST, clientKey).build()

    val schemes = paymentMethodsApiResponse.paymentMethods?.filter { it.type == "scheme" }
    var cardComponent : CardComponent = CardComponent.PROVIDER.get(
        activity = activity,
        paymentMethod = schemes!!.first(),
        configuration = cardConfiguration,
        callback = cardCallback,
    )


    override fun dispose() {
        Log.d(
            "AdyenCheckout",
            "DISPOSE VIEW"
        )
        cardComponent.delegate.componentParams
        cardComponent.delegate.onCleared()
        componentView.invalidate()
    }

    init {
        cardComponent.delegate

        componentView = AdyenComponentView(context)

        componentView.attach(cardComponent, activity)
    }
}

class CardComponentFactory(
    private val activity: ComponentActivity,
    private val checkoutFlutterApi: CheckoutFlutterApi,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        val cardCallback = CardCallback(checkoutFlutterApi)
        return CardComponent(activity, cardCallback, context, viewId, creationParams)
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
        val model = PlatformCommunicationModel(
            PlatformCommunicationType.PAYMENTCOMPONENT,
            data = paymentComponentJson.toString(),
        )
        checkoutFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
    }

    override fun onError(componentError: ComponentError) {
    }


}
