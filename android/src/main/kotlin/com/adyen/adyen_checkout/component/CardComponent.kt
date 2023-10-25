package com.adyen.adyen_checkout.component

import CardComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentCommunicationType
import ComponentFlutterApi
import android.content.Context
import android.util.Log
import android.view.View
import androidx.activity.ComponentActivity
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.card.CardComponentState
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentCallback
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.PaymentComponentData
import com.adyen.checkout.components.core.PaymentMethodsApiResponse
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
    private val componentWrapperView = ComponentWrapperView(activity, componentFlutterApi)

    override fun getView(): View = componentWrapperView

    override fun dispose() {
        Log.d("AdyenCheckout", "DISPOSE VIEW")
        cardComponent.delegate.onCleared()
    }

    init {
        componentWrapperView.addCard(cardComponent, activity)
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
        println("ERROR")
    }

    override fun onStateChanged(state: CardComponentState) {
        super.onStateChanged(state)

        println("STATE CHAGNED ${state.isInputValid}")
    }


}
