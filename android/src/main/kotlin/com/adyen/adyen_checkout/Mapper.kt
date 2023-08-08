package com.adyen.adyen_checkout

import Amount
import DropInConfigurationModel
import Environment
import SessionModel
import android.content.Context

object Mapper {

    fun SessionModel.mapToSessionModel(): com.adyen.checkout.sessions.core.SessionModel {
        return com.adyen.checkout.sessions.core.SessionModel(this.id, this.sessionData)
    }

    fun DropInConfigurationModel.mapToDropInConfiguration(context: Context): com.adyen.checkout.dropin.DropInConfiguration {
        val amount = this.amount.mapToAmount()
        return com.adyen.checkout.dropin.DropInConfiguration.Builder(
            context,
            this.environment.mapToEnvironment(),
            clientKey
        ).setAmount(amount).build();
    }

    fun Environment.mapToEnvironment(): com.adyen.checkout.core.Environment {
        //TODO map to actual value
        return com.adyen.checkout.core.Environment.TEST
    }

    fun Amount.mapToAmount(): com.adyen.checkout.components.core.Amount {
        return com.adyen.checkout.components.core.Amount(this.currency, this.value.toLong())
    }
}