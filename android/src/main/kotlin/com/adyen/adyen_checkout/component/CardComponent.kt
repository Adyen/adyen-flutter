package com.adyen.adyen_checkout.component

import CardComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.core.view.children
import androidx.core.view.doOnPreDraw
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject
import java.util.UUID

internal class CardComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : PlatformView {
    private val componentView: AdyenComponentView = AdyenComponentView(context)
    private val componentWrapperView = ComponentWrapperView(activity, componentView)
    private val screenDensity = context.resources.displayMetrics.density
    private val configuration = creationParams?.get("cardComponentConfiguration") as CardComponentConfigurationDTO
    private val paymentMethods = creationParams?.get("paymentMethods") as String
    private val paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(JSONObject(paymentMethods))
    private val schemes = paymentMethodsApiResponse.paymentMethods?.firstOrNull { it.type == "scheme" }
    private val environment = configuration.environment.toNativeModel()
    private val cardConfiguration = configuration.cardsConfiguration.toNativeModel(
        context,
        environment,
        configuration.clientKey
    )
    private var cardComponent: CardComponent = CardComponent.PROVIDER.get(
        activity = activity,
        paymentMethod = schemes!!,
        configuration = cardConfiguration,
        callback = CardCallback(componentFlutterApi),
        key = UUID.randomUUID().toString()
    )

    override fun getView(): View = componentWrapperView

    override fun dispose() {
        Log.d("AdyenCheckout", "DISPOSE VIEW")
        cardComponent.delegate.onCleared()
    }

    init {
        componentView.attach(cardComponent, activity)

        componentView.doOnPreDraw {
            componentView.findViewById<ViewGroup>(R.id.frameLayout_componentContainer).children.firstOrNull()?.let {
                val layoutParams = it.layoutParams
                layoutParams.height = LinearLayout.LayoutParams.WRAP_CONTENT
                it.layoutParams = layoutParams
            }

            val componentHeight = componentView.height / screenDensity
            componentFlutterApi.onComponentCommunication(
                ComponentCommunicationModel(type = ComponentCommunicationType.RESIZE, data = componentHeight)
            ) {}
        }
    }
}

class CardComponentFactory(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
) : PlatformViewFactory(ComponentFlutterApi.codec) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<*, *>?
        return CardComponent(activity, componentFlutterApi, context, viewId, creationParams)
    }
}

class CardCallback(private val componentFlutterApi: ComponentFlutterApi) : ComponentCallback<CardComponentState> {
    override fun onSubmit(state: CardComponentState) {
        Log.d("AdyenCheckout", state.toString())
        val paymentComponentJson = PaymentComponentData.SERIALIZER.serialize(state.data)
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.PAYMENTCOMPONENT,
            data = paymentComponentJson.toString(),
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
    }

    override fun onError(componentError: ComponentError) {
    }


}
