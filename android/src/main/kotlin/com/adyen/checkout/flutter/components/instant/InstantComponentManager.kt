package com.adyen.checkout.flutter.components.instant

import ComponentCommunicationModel
import ComponentFlutterInterface
import ErrorDTO
import InstantPaymentConfigurationDTO
import PaymentEventDTO
import PaymentResultDTO
import PaymentResultModelDTO
import android.content.Intent
import androidx.core.util.Consumer
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.PaymentMethod
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.instant.advanced.InstantComponentAdvancedCallback
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.instant.InstantPaymentComponent
import com.adyen.checkout.instant.InstantPaymentConfiguration
import com.adyen.checkout.redirect.RedirectComponent
import org.json.JSONObject

class InstantComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterInterface: ComponentFlutterInterface,
) {
    private var instantPaymentComponent: InstantPaymentComponent? = null
    private var componentId: String? = null

    fun startInstantComponent(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ): InstantPaymentComponent {
        val paymentMethod = PaymentMethod.SERIALIZER.deserialize(JSONObject(paymentMethodResponse))
        val configuration = instantPaymentConfigurationDTO.fromDTO(activity)
        val instantPaymentComponent = createInstantPaymentComponent(configuration, paymentMethod, componentId)
        this.instantPaymentComponent = instantPaymentComponent
        this.componentId = componentId
        ComponentLoadingBottomSheet.show(activity.supportFragmentManager, instantPaymentComponent)
        return instantPaymentComponent
    }

    fun onDispose(componentId: String) {
        if (componentId == this.componentId) {
            instantPaymentComponent = null
        }
    }

    private fun createInstantPaymentComponent(
        configuration: InstantPaymentConfiguration,
        paymentMethod: PaymentMethod,
        componentId: String,
    ): InstantPaymentComponent {
        return InstantPaymentComponent.PROVIDER.get(
            activity = activity,
            paymentMethod = paymentMethod,
            configuration = configuration,
            callback = InstantComponentAdvancedCallback(
                componentFlutterInterface,
                componentId,
                ::onLoading,
                ::hideLoadingBottomSheet
            ),
            key = componentId
        )
    }

    private fun onLoading(componentId: String) {
        val model =
            ComponentCommunicationModel(
                ComponentCommunicationType.LOADING,
                componentId = componentId,
            )
        componentFlutterInterface.onComponentCommunication(model) {}
    }

    private fun hideLoadingBottomSheet() = ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
}
