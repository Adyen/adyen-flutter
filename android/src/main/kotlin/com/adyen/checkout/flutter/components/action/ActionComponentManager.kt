package com.adyen.checkout.flutter.components.action

import ActionComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentFlutterInterface
import PaymentResultDTO
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.GenericActionComponent
import com.adyen.checkout.action.core.internal.ActionHandlingComponent
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import org.json.JSONObject
import java.util.UUID

internal class ActionComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val assignCurrentComponent: (ActionHandlingComponent?) -> Unit,
) {
    fun handleAction(
        actionComponentConfigurationDTO: ActionComponentConfigurationDTO,
        componentId: String,
        actionResponse: Map<String?, Any?>?
    ) {
        try {
            if (actionResponse == null) {
                sendErrorToFlutterLayer(componentId, "Action response not valid.")
                return
            }

            val checkoutConfiguration = actionComponentConfigurationDTO.mapToCheckoutConfiguration()
            val actionComponent = createActionComponent(checkoutConfiguration, componentId)
            val action = Action.SERIALIZER.deserialize(JSONObject(actionResponse))
            if (actionComponent.canHandleAction(action)) {
                assignCurrentComponent(actionComponent)
                ComponentLoadingBottomSheet.show(activity, actionComponent)
                actionComponent.handleAction(action, activity)
            } else {
                sendErrorToFlutterLayer(componentId, "Action component cannot handle action response.")
            }
        } catch (exception: Exception) {
            sendErrorToFlutterLayer(componentId, exception.message ?: "Action handling failed.")
        }
    }

    private fun createActionComponent(
        checkoutConfiguration: CheckoutConfiguration,
        componentId: String
    ): GenericActionComponent {
        return GenericActionComponent.PROVIDER.get(
            activity,
            checkoutConfiguration,
            ActionComponentCallback(
                activity,
                componentFlutterApi,
                componentId,
            ),
            UUID.randomUUID().toString()
        )
    }

    private fun sendErrorToFlutterLayer(
        componentId: String,
        errorMessage: String
    ) {
        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = PaymentResultDTO(PaymentResultEnum.ERROR, errorMessage),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
