package com.adyen.adyen_checkout.dropIn.models

data class DropInStoredPaymentMethodDeletionModel(
    val storedPaymentMethodId: String,
    val dropInFlowType: DropInFlowType
)
