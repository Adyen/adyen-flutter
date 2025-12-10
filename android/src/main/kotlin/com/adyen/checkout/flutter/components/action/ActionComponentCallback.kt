package com.adyen.checkout.flutter.components.action

import androidx.fragment.app.FragmentActivity
import com.adyen.checkout.components.core.ActionComponentCallback
import com.adyen.checkout.components.core.ActionComponentData
import com.adyen.checkout.components.core.ComponentError
import com.adyen.checkout.flutter.components.view.ComponentLoadingBottomSheet
import com.adyen.checkout.flutter.generated.ComponentCommunicationModel
import com.adyen.checkout.flutter.generated.ComponentCommunicationType
import com.adyen.checkout.flutter.generated.ComponentFlutterInterface
import com.adyen.checkout.flutter.generated.PaymentResultDTO
import com.adyen.checkout.flutter.generated.PaymentResultEnum

internal class ActionComponentCallback(
    private val activity: FragmentActivity,
    private val componentFlutterApi: ComponentFlutterInterface,
    private val componentId: String
) : ActionComponentCallback {
    override fun onAdditionalDetails(actionComponentData: ActionComponentData) {
        ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
        val data = ActionComponentData.SERIALIZER.serialize(actionComponentData).toString()
        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.ADDITIONAL_DETAILS,
                componentId = componentId,
                data = data,
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }

    override fun onError(componentError: ComponentError) {
        ComponentLoadingBottomSheet.hide(activity.supportFragmentManager)
        val type: PaymentResultEnum =
            when (componentError.exception) {
                is com.adyen.checkout.core.old.exception.CancellationException -> PaymentResultEnum.CANCELLED_BY_USER
                is com.adyen.checkout.threeds2.old.Cancelled3DS2Exception -> PaymentResultEnum.CANCELLED_BY_USER
                else -> PaymentResultEnum.ERROR
            }
        val model =
            ComponentCommunicationModel(
                type = ComponentCommunicationType.RESULT,
                componentId = componentId,
                paymentResult = PaymentResultDTO(type, componentError.errorMessage),
            )
        componentFlutterApi.onComponentCommunication(model) {}
    }
}
