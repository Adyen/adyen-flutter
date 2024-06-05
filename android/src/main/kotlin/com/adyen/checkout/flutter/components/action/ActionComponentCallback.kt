package com.adyen.checkout.flutter.components.action

import ComponentCommunicationModel
import ComponentFlutterInterface
import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.ActionComponentCallback
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import org.json.JSONObject

class ActionComponentCallback(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String
) : ActionComponentCallback {
    private val errorMessageKey = "errorMessage"
    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        val data = ActionComponentData.SERIALIZER.serialize(actionComponentData).toString()
        ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
        sendToFlutterLayer(data)
    }

    override fun onError(componentError: ComponentError) {
        val data = JSONObject(mapOf(errorMessageKey to componentError.errorMessage)).toString()
        ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
        sendToFlutterLayer(data)
    }

    private fun sendToFlutterLayer(data: String) {
        val model = ComponentCommunicationModel(
            ComponentCommunicationType.RESULT,
            componentId,
            data
        )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
