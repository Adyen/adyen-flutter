package com.adyen.adyen_checkout.utils

import AddressMode
import Amount
import DropInConfigurationDTO
import Environment
import GooglePayConfigurationDTO
import GooglePayEnvironment
import OrderResponseModel
import Session
import android.content.Context
import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.card.CardType
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.sessions.core.SessionModel
import com.google.android.gms.wallet.WalletConstants
import com.adyen.checkout.core.Environment as SDKEnvironment

object Mapper {

    fun Session.mapToSession(): SessionModel {
        return SessionModel(this.id, this.sessionData)
    }

    fun OrderResponse.mapToOrderResponseModel(): OrderResponseModel {
        return OrderResponseModel(
            pspReference = pspReference,
            orderData = orderData,
            amount = amount?.mapTopAmount(),
            remainingAmount = remainingAmount?.mapTopAmount(),
        )
    }

    fun DropInConfigurationDTO.mapToDropInConfiguration(context: Context): DropInConfiguration {
        val environment = this.environment.mapToEnvironment()
        val amount = this.amount.mapToAmount()
        val cardConfiguration = CardConfiguration.Builder(
            context = context,
            environment = environment,
            clientKey = this.clientKey
        )
            .setShowStorePaymentField(cardsConfigurationDTO?.showStorePaymentField ?: false)
            .setAddressConfiguration(
                cardsConfigurationDTO?.addressMode?.mapToAddressConfiguration()
                    ?: AddressConfiguration.None
            )
            .setShowStorePaymentField(cardsConfigurationDTO?.showStorePaymentField ?: false)
            .setHideCvcStoredCard(cardsConfigurationDTO?.showCvcForStoredCard ?: true)
            .setHideCvc(cardsConfigurationDTO?.showCvc ?: true)
            .setKcpAuthVisibility(determineKcpAuthVisibility(cardsConfigurationDTO?.showKcpField))
            .setSocialSecurityNumberVisibility(
                determineSocialSecurityNumberVisibility(cardsConfigurationDTO?.showSocialSecurityNumberField)
            )
            .setSupportedCardTypes(*mapToSupportedCardTypes(cardsConfigurationDTO?.supportedCardTypes))
            .setHolderNameRequired(cardsConfigurationDTO?.holderNameRequired ?: false)
            .build()
        val dropInConfiguration = DropInConfiguration.Builder(context, environment, clientKey)
            .setAmount(amount)
            .addCardConfiguration(cardConfiguration)

        if (googlePayConfigurationDTO != null) {
            val googlePayConfigurationBuilder = GooglePayConfiguration.Builder(context, environment, clientKey)
            val googlePayConfiguration =
                googlePayConfigurationDTO.mapToGooglePayConfiguration(googlePayConfigurationBuilder)
            dropInConfiguration.addGooglePayConfiguration(googlePayConfiguration)
        }

        return dropInConfiguration.build()
    }

    private fun AddressMode.mapToAddressConfiguration(): AddressConfiguration {
        return when (this) {
            AddressMode.FULL -> AddressConfiguration.FullAddress()
            AddressMode.POSTALCODE -> AddressConfiguration.PostalCode()
            AddressMode.NONE -> AddressConfiguration.None
        }
    }

    private fun determineKcpAuthVisibility(visible: Boolean?): KCPAuthVisibility {
        return when (visible) {
            true -> KCPAuthVisibility.SHOW
            else -> KCPAuthVisibility.HIDE
        }
    }

    private fun determineSocialSecurityNumberVisibility(visible: Boolean?): SocialSecurityNumberVisibility {
        return when (visible) {
            true -> SocialSecurityNumberVisibility.SHOW
            else -> SocialSecurityNumberVisibility.HIDE
        }
    }

    private fun mapToSupportedCardTypes(cardTypes: List<String?>?): Array<CardType> {
        if (cardTypes == null) {
            return emptyArray()
        }

        val mappedCardTypes = cardTypes.map { cardBrandName ->
            cardBrandName?.let { CardType.getByBrandName(it.lowercase()) }
        }
        return mappedCardTypes.filterNotNull().toTypedArray()
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

    private fun GooglePayConfigurationDTO.mapToGooglePayConfiguration(builder: GooglePayConfiguration.Builder): GooglePayConfiguration {
        builder.setMerchantAccount(merchantAccount)
        builder.setAllowedCardNetworks(allowedCardNetworks.filterNotNull())
        builder.setAllowedAuthMethods(allowedAuthMethods.filterNotNull())
        builder.setTotalPriceStatus(totalPriceStatus.toString())
        builder.setAllowPrepaidCards(allowPrepaidCards)
        builder.setBillingAddressRequired(billingAddressRequired)
        builder.setEmailRequired(emailRequired)
        builder.setShippingAddressRequired(shippingAddressRequired)
        builder.setGooglePayEnvironment(googlePayEnvironment.mapToWalletConstants())
        return builder.build()
    }

    private fun GooglePayEnvironment.mapToWalletConstants(): Int {
        return when (this) {
            GooglePayEnvironment.TEST -> WalletConstants.ENVIRONMENT_TEST
            GooglePayEnvironment.PRODUCTION -> WalletConstants.ENVIRONMENT_PRODUCTION
        }
    }
}
