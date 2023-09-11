package com.adyen.adyen_checkout.utils

import Amount
import Configuration
import Environment
import OrderResponseModel
import Session
import android.content.Context
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.core.Environment as SDKEnvironment

object Mapper {

    fun Session.mapToSession(): com.adyen.checkout.sessions.core.SessionModel {
        return com.adyen.checkout.sessions.core.SessionModel(this.id, this.sessionData)
    }

    fun Configuration.mapToDropInConfiguration(context: Context): com.adyen.checkout.dropin.DropInConfiguration {
        val amount = this.amount.mapToAmount()
        return com.adyen.checkout.dropin.DropInConfiguration.Builder(
            context,
            this.environment.mapToEnvironment(),
            clientKey
        ).setAmount(amount).build();
    }

    private fun Environment.mapToEnvironment(): com.adyen.checkout.core.Environment {
        return when (this) {
            Environment.TEST -> SDKEnvironment.TEST
            Environment.EUROPE -> SDKEnvironment.EUROPE
            Environment.UNITEDSTATES -> SDKEnvironment.UNITED_STATES
            Environment.AUSTRALIA -> SDKEnvironment.AUSTRALIA
            Environment.INDIA -> SDKEnvironment.INDIA
            Environment.APSE -> SDKEnvironment.APSE
        }

    }

    private fun Amount.mapToAmount(): com.adyen.checkout.components.core.Amount {
        return com.adyen.checkout.components.core.Amount(this.currency, this.value)
    }

    private fun com.adyen.checkout.components.core.Amount.mapTopAmount(): Amount {
        return Amount(this.currency, this.value)
    }

    fun OrderResponse.mapToOrderResponseModel(): OrderResponseModel {
        return OrderResponseModel(
            pspReference = pspReference,
            orderData = orderData,
            amount = amount?.mapTopAmount(),
            remainingAmount = remainingAmount?.mapTopAmount()
        )
    }
}