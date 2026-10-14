package com.adyen.checkout.flutter.components

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.adyen.checkout.flutter.generated.CheckoutEventDTO
import com.adyen.checkout.flutter.generated.CheckoutEventTypeDTO
import io.flutter.plugin.platform.PlatformView

internal class FailedCheckoutPaymentView(
    context: Context,
    checkoutId: String?,
    componentId: String?,
    eventHandler: ComponentPlatformEventHandler,
    error: Throwable,
) : PlatformView {
    private val view = FrameLayout(context)

    init {
        if (checkoutId != null && componentId != null) {
            view.post {
                eventHandler.send(
                    CheckoutEventDTO(
                        type = CheckoutEventTypeDTO.FAILURE,
                        checkoutId = checkoutId,
                        componentId = componentId,
                        errorCode = "PaymentMethodFailure",
                        errorMessage = error.message,
                    ),
                )
            }
        }
    }

    override fun getView(): View = view

    override fun dispose() = Unit
}
