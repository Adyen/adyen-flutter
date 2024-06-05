package com.adyen.checkout.flutter.components.action

import ActionComponentConfigurationDTO
import ComponentCommunicationModel
import ComponentFlutterInterface
import PaymentResultDTO
import PaymentResultEnum
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.action.core.GenericActionComponent
import com.adyen.checkout.components.core.ActionComponentCallback
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.components.core.action.Action
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToCheckoutConfiguration
import org.json.JSONObject
import java.util.UUID

class ActionComponentManager(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
) {
    private var actionComponent: GenericActionComponent? = null
    private var componentId: String? = null
    fun createActionComponent(
        actionComponentConfigurationDTO: ActionComponentConfigurationDTO, componentId: String
    ): GenericActionComponent {
        val checkoutConfiguration = actionComponentConfigurationDTO.mapToCheckoutConfiguration()
        val genericActionComponent = GenericActionComponent.PROVIDER.get(
            activity, checkoutConfiguration, ActionComponentCallback(
                activity,
                componentFlutterApi,
                componentId,
            ), UUID.randomUUID().toString()
        )

        this.componentId = componentId
        this.actionComponent = genericActionComponent
        return genericActionComponent
    }

    fun handleAction(actionResponse: Map<String?, Any?>) {
        actionComponent?.let { actionComponent ->
            val action = Action.SERIALIZER.deserialize(JSONObject(actionResponse))
            if (actionComponent.canHandleAction(action)) {
                ComponentLoadingBottomSheet.show(activity.supportFragmentManager, actionComponent)
                actionComponent.handleAction(action, activity)
            }
        }
    }

    fun onDispose(componentId: String) {
        if (componentId == this.componentId) {
            actionComponent = null
        }
    }

}

