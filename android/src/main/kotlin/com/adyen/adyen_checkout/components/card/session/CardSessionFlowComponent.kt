package com.adyen.adyen_checkout.components.card.session

import CardComponentConfigurationDTO
import ComponentFlutterApi
import android.content.Context
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.activity.ComponentActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.children
import androidx.core.view.doOnNextLayout
import androidx.lifecycle.lifecycleScope
import com.adyen.adyen_checkout.R
import com.adyen.adyen_checkout.components.ComponentMessenger
import com.adyen.adyen_checkout.components.ComponentWrapperView
import com.adyen.adyen_checkout.utils.ConfigurationMapper.toNativeModel
import com.adyen.checkout.card.CardComponent
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.sessions.core.CheckoutSession
import com.adyen.checkout.sessions.core.CheckoutSessionProvider
import com.adyen.checkout.sessions.core.CheckoutSessionResult
import com.adyen.checkout.sessions.core.SessionModel
import com.adyen.checkout.ui.core.AdyenComponentView
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.launch
import org.json.JSONObject

internal class CardSessionFlowComponent(
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterApi,
    context: Context,
    id: Int,
    creationParams: Map<*, *>?
) : PlatformView {
    private val configuration = creationParams?.get("cardComponentConfiguration") as CardComponentConfigurationDTO
    private val sessionResponse = creationParams?.get("sessionResponse") as String
    private val sessionModel = SessionModel.SERIALIZER.deserialize(JSONObject(sessionResponse))
    private val environment = configuration.environment.toNativeModel()
    private val cardConfiguration = configuration.cardConfiguration.toNativeModel(
        context,
        environment,
        configuration.clientKey
    )

    private val componentWrapperView = ComponentWrapperView(activity, componentFlutterApi)
    private lateinit var cardComponent: CardComponent

    init {
        activity.lifecycleScope.launch {
            val checkoutSession: CheckoutSession? = getCheckoutSession(sessionModel, cardConfiguration)
            if (checkoutSession == null) {
                Log.e("AdyenCheckout", "Failed to fetch session")
                //TODO error handling
                //_cardViewState.emit(CardViewState.Error)
                return@launch
            }

            val paymentMethod = checkoutSession.getPaymentMethod(PaymentMethodTypes.SCHEME)
            if (paymentMethod == null) {
                Log.e("AdyenCheckout", "Session does not contain SCHEME payment method")
                //TODO error handling
                //_cardViewState.emit(CardViewState.Error)
                return@launch
            }

            cardComponent = CardComponent.PROVIDER.get(
                activity = activity,
                checkoutSession = checkoutSession,
                paymentMethod = paymentMethod,
                configuration = cardConfiguration,
                componentCallback = CardSessionFlowCallback(componentFlutterApi) { action -> onAction(action) },
            )

            componentWrapperView.addComponent(cardComponent)
        }
    }

    override fun getView(): View = componentWrapperView

    override fun onFlutterViewAttached(flutterView: View) {
        super.onFlutterViewAttached(flutterView)

        flutterView.doOnNextLayout {
            adjustCardComponentLayout(it)
        }
    }

    override fun dispose() {
        ComponentMessenger.instance().removeObservers(activity)
    }

    private fun adjustCardComponentLayout(flutterView: View) {
        val linearLayoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        //Adyen component view
        val adyenComponentView = flutterView.findViewById<AdyenComponentView>(R.id.adyen_component_view)
        adyenComponentView.layoutParams = ConstraintLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )

        //Component container
        val componentContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_componentContainer)
        componentContainer.layoutParams = linearLayoutParams

        //Button container
        val buttonContainer = flutterView.findViewById<FrameLayout>(R.id.frameLayout_buttonContainer)
        buttonContainer.layoutParams = linearLayoutParams

        //Pay button
        val button = buttonContainer.children.firstOrNull()
        val buttonParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        )
        button?.layoutParams = buttonParams

        //Card
        val card = componentContainer.children.firstOrNull() as ViewGroup?
        val cardLayoutParams = card?.layoutParams
        cardLayoutParams?.height = LinearLayout.LayoutParams.WRAP_CONTENT
        card?.layoutParams = cardLayoutParams
    }


    private suspend fun getCheckoutSession(
        sessionModel: SessionModel,
        cardConfiguration: CardConfiguration,
    ): CheckoutSession? {
        return when (val result = CheckoutSessionProvider.createSession(sessionModel, cardConfiguration)) {
            is CheckoutSessionResult.Success -> result.checkoutSession
            is CheckoutSessionResult.Error -> null
        }
    }

    private fun onAction(action: Action) = cardComponent.handleAction(action, activity)
}
