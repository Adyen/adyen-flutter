package com.adyen.checkout.flutter.components.card

import android.view.View
import androidx.activity.ComponentActivity
import com.adyen.checkout.card.old.CardComponent
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import com.adyen.checkout.flutter.generated.BinLookupDataDTO
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.flutter.utils.Constants
import io.flutter.plugin.platform.PlatformView

abstract class BaseCardComponent(
    private val creationParams: Map<*, *>,
    private val activity: ComponentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentEventHandler: ComponentPlatformEventHandler,
    private val onDispose: (String) -> Unit,
    private val setCurrentCardComponent: (BaseCardComponent) -> Unit,
) : PlatformView {
    internal var cardComponent: CardComponent? = null
    internal val checkoutConfiguration =
        (creationParams[Constants.CARD_COMPONENT_CONFIGURATION_KEY] as CardComponentConfigurationDTO)
            .toCheckoutConfiguration()
    internal val paymentMethodString =
        creationParams[Constants.PAYMENT_METHOD_KEY] as String
    internal val componentId =
        creationParams[Constants.COMPONENT_ID_KEY] as String
    internal val isStoredPaymentMethod = creationParams[IS_STORED_PAYMENT_METHOD_KEY] as Boolean? ?: false
    private val dynamicComponentView = DynamicComponentView(activity, componentId, componentEventHandler)

    override fun getView(): View = dynamicComponentView

    override fun dispose() {
        dynamicComponentView.onDispose()
        cardComponent = null
        onDispose(componentId)
    }

    fun addComponent(cardComponent: CardComponent) {
        setOnBinLookupListener(cardComponent)
        setOnBinValueListener(cardComponent)
//        dynamicComponentView.addComponent(cardComponent, activity)
    }

    fun setCurrentCardComponent() = setCurrentCardComponent(this)

    private fun setOnBinLookupListener(cardComponent: CardComponent) {
        cardComponent.setOnBinLookupListener { binLookupData ->
            val binLookupDataDtoList = binLookupData.map { BinLookupDataDTO(it.brand) }
            val componentCommunicationModel =
                ComponentCommunicationModel(
                    ComponentCommunicationType.BIN_LOOKUP,
                    componentId,
                    binLookupDataDtoList
                )
            componentFlutterApi.onComponentCommunication(componentCommunicationModel) {}
        }
    }

    private fun setOnBinValueListener(cardComponent: CardComponent) {
        cardComponent.setOnBinValueListener { binValue ->
            val componentCommunicationModel =
                ComponentCommunicationModel(
                    ComponentCommunicationType.BIN_VALUE,
                    componentId,
                    binValue
                )
            componentFlutterApi.onComponentCommunication(componentCommunicationModel) {}
        }
    }

    companion object {
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
        const val CARD_PAYMENT_METHOD_KEY = "scheme"
    }
}
