package com.adyen.checkout.flutter.dropIn

import com.adyen.checkout.core.action.data.ActionComponentData
import com.adyen.checkout.core.components.AdditionalDetailsResult
import com.adyen.checkout.core.components.SubmitResult
import com.adyen.checkout.core.components.data.PaymentComponentData
import com.adyen.checkout.dropin.DropInService

/**
 * Concrete [DropInService] used for session Drop-in. Drop-in starts a service instance on launch;
 * for sessions the submit and additional-details calls are handled internally by the session, so
 * these callbacks are never invoked.
 */
internal class AdyenCheckoutDropInService : DropInService() {
    override suspend fun onSubmit(data: PaymentComponentData<*>): SubmitResult =
        SubmitResult.Retry("Session Drop-in does not use onSubmit.")

    override suspend fun onAdditionalDetails(data: ActionComponentData): AdditionalDetailsResult =
        AdditionalDetailsResult.Completion("Error")
}
