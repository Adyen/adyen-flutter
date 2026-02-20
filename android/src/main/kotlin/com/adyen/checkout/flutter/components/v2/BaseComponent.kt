package com.adyen.checkout.flutter.components.v2

import android.content.Context
import android.view.View
import androidx.activity.ComponentActivity
import com.adyen.checkout.card.old.CardComponent
import com.adyen.checkout.flutter.components.ComponentPlatformEventHandler
import com.adyen.checkout.flutter.components.view.DynamicComponentView
import com.adyen.checkout.flutter.generated.AdyenFlutterInterface
import com.adyen.checkout.flutter.generated.BinLookupDataDTO
import com.adyen.checkout.flutter.generated.CheckoutConfigurationDTO
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.session.CheckoutHolder
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import io.flutter.plugin.platform.PlatformView

abstract class BaseComponent(
    private val activity: ComponentActivity,
    private val creationParams: Map<*, *>,
    private val onDispose: (String) -> Unit,
    private val platformEventHandler: ComponentPlatformEventHandler
) : PlatformView {
    internal val componentId = creationParams[COMPONENT_ID_KEY] as String? ?: ""
    internal val isStoredPaymentMethod = creationParams[IS_STORED_PAYMENT_METHOD_KEY] as Boolean? ?: false
    internal val dynamicComponentView =
        DynamicComponentView(activity, componentId, platformEventHandler)
    internal var cardComponent: CardComponent? = null

    override fun getView(): View = dynamicComponentView

    override fun dispose() {
        dynamicComponentView.onDispose()
        cardComponent = null
        onDispose(componentId)
    }

    private fun setOnBinLookupListener(cardComponent: CardComponent) {
        cardComponent.setOnBinLookupListener { binLookupData ->
            val binLookupDataDtoList = binLookupData.map { BinLookupDataDTO(it.brand) }
            val componentCommunicationModel =
                ComponentCommunicationModel(
                    ComponentCommunicationType.BIN_LOOKUP,
                    componentId,
                    binLookupDataDtoList
                )
            platformEventHandler.eventSink?.success(componentCommunicationModel)
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
            platformEventHandler.eventSink?.success(componentCommunicationModel)
        }
    }

    companion object {
        const val PAYMENT_METHOD_KEY = "paymentMethod"
        const val IS_STORED_PAYMENT_METHOD_KEY = "isStoredPaymentMethod"
        const val COMPONENT_ID_KEY = "componentId"
    }
}
