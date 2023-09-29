package com.adyen.adyen_checkout.utils

import AddressMode
import AmountDTO
import CardsConfigurationDTO
import CashAppPayConfigurationDTO
import CashAppPayEnvironment
import DropInConfigurationDTO
import Environment
import FieldVisibility
import GooglePayConfigurationDTO
import GooglePayEnvironment
import OrderResponseDTO
import SessionDTO
import TotalPriceStatus
import android.content.Context
import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.card.CardType
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.cashapppay.CashAppPayConfiguration
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.sessions.core.SessionModel
import com.google.android.gms.wallet.WalletConstants
import java.util.Locale
import com.adyen.checkout.cashapppay.CashAppPayEnvironment as SDKCashAppPayEnvironment
import com.adyen.checkout.core.Environment as SDKEnvironment

object ConfigurationMapper {

    fun SessionDTO.mapToSession(): SessionModel {
        return SessionModel(this.id, this.sessionData)
    }

    fun OrderResponse.mapToOrderResponseModel(): OrderResponseDTO {
        return OrderResponseDTO(
            pspReference = pspReference,
            orderData = orderData,
            amount = amount?.mapToDTOAmount(),
            remainingAmount = remainingAmount?.mapToDTOAmount(),
        )
    }

    fun DropInConfigurationDTO.mapToDropInConfiguration(context: Context): DropInConfiguration {
        val environment = environment.mapToEnvironment()
        val amount = amount.mapToAmount()
        val shopperLocale = Locale.forLanguageTag(shopperLocale)
        val dropInConfiguration = DropInConfiguration.Builder(shopperLocale, environment, clientKey)

        if (cardsConfigurationDTO != null) {
            val cardConfiguration = buildCardConfiguration(context, environment, cardsConfigurationDTO)
            dropInConfiguration.addCardConfiguration(cardConfiguration)
        }

        if (googlePayConfigurationDTO != null) {
            val googlePayConfiguration =
                buildGooglePayConfiguration(shopperLocale, environment, googlePayConfigurationDTO)
            dropInConfiguration.addGooglePayConfiguration(googlePayConfiguration)
        }

        if (cashAppPayConfigurationDTO != null) {
            val cashAppPayConfiguration =
                buildCashAppPayConfiguration(shopperLocale, environment, cashAppPayConfigurationDTO)
            dropInConfiguration.addCashAppPayConfiguration(cashAppPayConfiguration)
        }

        dropInConfiguration.setAmount(amount)
        return dropInConfiguration.build()
    }

    private fun DropInConfigurationDTO.buildCardConfiguration(
        context: Context,
        environment: com.adyen.checkout.core.Environment,
        cardsConfigurationDTO: CardsConfigurationDTO
    ): CardConfiguration {
        return CardConfiguration.Builder(
            context = context,
            environment = environment,
            clientKey = clientKey
        )
            .setShowStorePaymentField(cardsConfigurationDTO.showStorePaymentField)
            .setAddressConfiguration(
                cardsConfigurationDTO.addressMode.mapToAddressConfiguration()
            )
            .setShowStorePaymentField(cardsConfigurationDTO.showStorePaymentField)
            .setHideCvcStoredCard(!cardsConfigurationDTO.showCvcForStoredCard)
            .setHideCvc(!cardsConfigurationDTO.showCvc)
            .setKcpAuthVisibility(determineKcpAuthVisibility(cardsConfigurationDTO.kcpFieldVisibility))
            .setSocialSecurityNumberVisibility(
                determineSocialSecurityNumberVisibility(cardsConfigurationDTO.socialSecurityNumberFieldVisibility)
            )
            .setSupportedCardTypes(*mapToSupportedCardTypes(cardsConfigurationDTO.supportedCardTypes))
            .setHolderNameRequired(cardsConfigurationDTO.holderNameRequired)
            .build()
    }

    private fun DropInConfigurationDTO.buildGooglePayConfiguration(
        shopperLocale: Locale,
        environment: com.adyen.checkout.core.Environment,
        googlePayConfigurationDTO: GooglePayConfigurationDTO
    ): GooglePayConfiguration {
        val googlePayConfigurationBuilder = GooglePayConfiguration.Builder(
            shopperLocale,
            environment,
            clientKey
        )
        return googlePayConfigurationDTO.mapToGooglePayConfiguration(googlePayConfigurationBuilder)
    }

    private fun DropInConfigurationDTO.buildCashAppPayConfiguration(
        shopperLocale: Locale,
        environment: com.adyen.checkout.core.Environment,
        cashAppPayConfigurationDTO: CashAppPayConfigurationDTO
    ): CashAppPayConfiguration {
        val cashAppPayConfigurationBuilder = CashAppPayConfiguration.Builder(
            shopperLocale,
            environment,
            clientKey
        )
        return cashAppPayConfigurationDTO.mapToCashAppPayConfiguration(cashAppPayConfigurationBuilder)
    }

    private fun AddressMode.mapToAddressConfiguration(): AddressConfiguration {
        return when (this) {
            AddressMode.FULL -> AddressConfiguration.FullAddress()
            AddressMode.POSTALCODE -> AddressConfiguration.PostalCode()
            AddressMode.NONE -> AddressConfiguration.None
        }
    }

    private fun determineKcpAuthVisibility(fieldVisibility: FieldVisibility): KCPAuthVisibility {
        return when (fieldVisibility) {
            FieldVisibility.SHOW -> KCPAuthVisibility.SHOW
            FieldVisibility.HIDE -> KCPAuthVisibility.HIDE
        }
    }

    private fun determineSocialSecurityNumberVisibility(visible: FieldVisibility): SocialSecurityNumberVisibility {
        return when (visible) {
            FieldVisibility.SHOW -> SocialSecurityNumberVisibility.SHOW
            FieldVisibility.HIDE -> SocialSecurityNumberVisibility.HIDE
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

    private fun Environment.mapToEnvironment(): SDKEnvironment {
        return when (this) {
            Environment.TEST -> SDKEnvironment.TEST
            Environment.EUROPE -> SDKEnvironment.EUROPE
            Environment.UNITEDSTATES -> SDKEnvironment.UNITED_STATES
            Environment.AUSTRALIA -> SDKEnvironment.AUSTRALIA
            Environment.INDIA -> SDKEnvironment.INDIA
            Environment.APSE -> SDKEnvironment.APSE
        }
    }

    private fun AmountDTO.mapToAmount(): Amount {
        return Amount(this.currency, this.value)
    }

    private fun Amount.mapToDTOAmount(): AmountDTO {
        return AmountDTO(this.currency, this.value)
    }

    private fun GooglePayConfigurationDTO.mapToGooglePayConfiguration(builder: GooglePayConfiguration.Builder):
        GooglePayConfiguration {
        if (allowedCardNetworks.isNotEmpty()) {
            builder.setAllowedCardNetworks(allowedCardNetworks.filterNotNull())
        }

        if (allowedAuthMethods.isNotEmpty()) {
            builder.setAllowedAuthMethods(allowedAuthMethods.filterNotNull())
        }

        merchantAccount?.let { merchantAccount ->
            builder.setMerchantAccount(merchantAccount)
        }

        totalPriceStatus?.let { totalPriceStatus ->
            builder.setTotalPriceStatus(totalPriceStatus.mapToTotalPriceStatus())
        }

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

    private fun TotalPriceStatus.mapToTotalPriceStatus(): String {
        return when (this) {
            TotalPriceStatus.NOTCURRENTLYKNOWN -> "NOT_CURRENTLY_KNOWN"
            TotalPriceStatus.ESTIMATED -> "ESTIMATED"
            TotalPriceStatus.FINALPRICE -> "FINAL"
        }
    }

    private fun CashAppPayConfigurationDTO.mapToCashAppPayConfiguration(builder: CashAppPayConfiguration.Builder):
        CashAppPayConfiguration {
        builder
            .setCashAppPayEnvironment(cashAppPayEnvironment.mapToCashAppPayEnvironment())
            .setReturnUrl(returnUrl)
        return builder.build()
    }

    private fun CashAppPayEnvironment.mapToCashAppPayEnvironment(): SDKCashAppPayEnvironment {
        return when (this) {
            CashAppPayEnvironment.SANDBOX -> SDKCashAppPayEnvironment.SANDBOX
            CashAppPayEnvironment.PRODUCTION -> SDKCashAppPayEnvironment.PRODUCTION
        }
    }
}
