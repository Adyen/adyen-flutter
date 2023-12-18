package com.adyen.checkout.flutter.dropIn.model

data class DropInStoredPaymentMethodDeletionModel(
    val storedPaymentMethodId: String,
    val dropInFlowType: DropInType
)
