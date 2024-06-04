package com.adyen.checkout.flutter.utils

import AddressMode
import AmountDTO
import AnalyticsOptionsDTO
import BillingAddressParametersDTO
import CardConfigurationDTO
import CashAppPayConfigurationDTO
import CashAppPayEnvironment
import DropInConfigurationDTO
import EncryptedCardDTO
import Environment
import FieldVisibility
import GooglePayConfigurationDTO
import GooglePayEnvironment
import InstantPaymentConfigurationDTO
import MerchantInfoDTO
import OrderResponseDTO
import ShippingAddressParametersDTO
import TotalPriceStatus
import UnencryptedCardDTO
import android.content.Context
import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.card.CardType
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.cashapppay.CashAppPayConfiguration
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.AnalyticsConfiguration
import com.adyen.checkout.components.core.AnalyticsLevel
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.components.core.internal.analytics.AnalyticsPlatform
import com.adyen.checkout.components.core.internal.analytics.AnalyticsPlatformParams
import com.adyen.checkout.cse.EncryptedCard
import com.adyen.checkout.cse.UnencryptedCard
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.googlepay.BillingAddressParameters
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.googlepay.MerchantInfo
import com.adyen.checkout.googlepay.ShippingAddressParameters
import com.google.android.gms.wallet.WalletConstants
import java.util.Locale
import com.adyen.checkout.cashapppay.CashAppPayEnvironment as SDKCashAppPayEnvironment
import com.adyen.checkout.core.Environment as SDKEnvironment

object ConfigurationMapper {
    fun OrderResponse.mapToOrderResponseModel(): OrderResponseDTO {
        return OrderResponseDTO(
            pspReference = pspReference,
            orderData = orderData,
            amount = amount?.mapToDTOAmount(),
            remainingAmount = remainingAmount?.mapToDTOAmount(),
        )
    }

    fun DropInConfigurationDTO.mapToDropInConfiguration(context: Context): DropInConfiguration {
        val environment = environment.toNativeModel()
        val amount = amount?.toNativeModel()
        val dropInConfiguration = buildDropInConfiguration(context, shopperLocale, environment)
        val analyticsConfiguration = analyticsOptionsDTO.mapToAnalyticsConfiguration()

        isRemoveStoredPaymentMethodEnabled.let {
            dropInConfiguration.setEnableRemovingStoredPaymentMethods(it)
        }

        showPreselectedStoredPaymentMethod.let {
            dropInConfiguration.setShowPreselectedStoredPaymentMethod(it)
        }

        skipListWhenSinglePaymentMethod.let {
            dropInConfiguration.setSkipListWhenSinglePaymentMethod(it)
        }

        if (cardConfigurationDTO != null) {
            val cardConfiguration =
                cardConfigurationDTO.mapToCardConfiguration(
                    context,
                    shopperLocale,
                    environment,
                    clientKey,
                    analyticsConfiguration,
                    amount,
                )
            dropInConfiguration.addCardConfiguration(cardConfiguration)
        }

        if (googlePayConfigurationDTO != null) {
            val googlePayConfiguration =
                buildGooglePayConfiguration(context, shopperLocale, environment, googlePayConfigurationDTO)
            dropInConfiguration.addGooglePayConfiguration(googlePayConfiguration)
        }

        if (cashAppPayConfigurationDTO != null) {
            val cashAppPayConfiguration =
                buildCashAppPayConfiguration(context, shopperLocale, environment, cashAppPayConfigurationDTO)
            dropInConfiguration.addCashAppPayConfiguration(cashAppPayConfiguration)
        }

        amount?.let {
            dropInConfiguration.setAmount(it)
        }

        return dropInConfiguration.build()
    }

    private fun DropInConfigurationDTO.buildDropInConfiguration(
        context: Context,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
    ): DropInConfiguration.Builder {
        return if (shopperLocale != null) {
            val locale = Locale.forLanguageTag(shopperLocale)
            DropInConfiguration.Builder(locale, environment, clientKey)
        } else {
            DropInConfiguration.Builder(context, environment, clientKey)
        }
    }

    fun CardConfigurationDTO.mapToCardConfiguration(
        context: Context,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
        clientKey: String,
        analyticsConfiguration: AnalyticsConfiguration,
        amount: Amount?,
    ): CardConfiguration {
        val cardConfiguration =
            if (shopperLocale != null) {
                val locale = Locale.forLanguageTag(shopperLocale)
                CardConfiguration.Builder(locale, environment, clientKey)
            } else {
                CardConfiguration.Builder(context, environment, clientKey)
            }

        cardConfiguration
            .setAddressConfiguration(addressMode.mapToAddressConfiguration())
            .setShowStorePaymentField(showStorePaymentField).setHideCvcStoredCard(!showCvcForStoredCard)
            .setHideCvc(!showCvc).setKcpAuthVisibility(determineKcpAuthVisibility(kcpFieldVisibility))
            .setSocialSecurityNumberVisibility(
                determineSocialSecurityNumberVisibility(socialSecurityNumberFieldVisibility)
            )
            .setSupportedCardTypes(*mapToSupportedCardTypes(supportedCardTypes))
            .setHolderNameRequired(holderNameRequired).setAnalyticsConfiguration(analyticsConfiguration)
        amount?.let {
            cardConfiguration.setAmount(amount)
        }
        return cardConfiguration.build()
    }

    fun AnalyticsOptionsDTO.mapToAnalyticsConfiguration(): AnalyticsConfiguration {
        val analyticsLevel =
            when {
                enabled -> AnalyticsLevel.ALL
                else -> AnalyticsLevel.NONE
            }
        AnalyticsPlatformParams.overrideForCrossPlatform(AnalyticsPlatform.FLUTTER, version)
        return AnalyticsConfiguration(analyticsLevel)
    }

    private fun DropInConfigurationDTO.buildGooglePayConfiguration(
        context: Context,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
        googlePayConfigurationDTO: GooglePayConfigurationDTO
    ): GooglePayConfiguration {
        val googlePayConfigurationBuilder =
            if (shopperLocale != null) {
                val locale = Locale.forLanguageTag(shopperLocale)
                GooglePayConfiguration.Builder(locale, environment, clientKey)
            } else {
                GooglePayConfiguration.Builder(context, environment, clientKey)
            }

        return googlePayConfigurationDTO.mapToGooglePayConfiguration(googlePayConfigurationBuilder)
    }

    private fun DropInConfigurationDTO.buildCashAppPayConfiguration(
        context: Context,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
        cashAppPayConfigurationDTO: CashAppPayConfigurationDTO
    ): CashAppPayConfiguration {
        val cashAppPayConfigurationBuilder =
            if (shopperLocale != null) {
                val locale = Locale.forLanguageTag(shopperLocale)
                CashAppPayConfiguration.Builder(locale, environment, clientKey)
            } else {
                CashAppPayConfiguration.Builder(context, environment, clientKey)
            }

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

        val mappedCardTypes =
            cardTypes.map { cardBrandName ->
                cardBrandName?.let { CardType.getByBrandName(it.lowercase()) }
            }
        return mappedCardTypes.filterNotNull().toTypedArray()
    }

    fun Environment.toNativeModel(): SDKEnvironment {
        return when (this) {
            Environment.TEST -> SDKEnvironment.TEST
            Environment.EUROPE -> SDKEnvironment.EUROPE
            Environment.UNITEDSTATES -> SDKEnvironment.UNITED_STATES
            Environment.AUSTRALIA -> SDKEnvironment.AUSTRALIA
            Environment.INDIA -> SDKEnvironment.INDIA
            Environment.APSE -> SDKEnvironment.APSE
        }
    }

    fun AmountDTO.toNativeModel(): Amount {
        return Amount(this.currency, this.value)
    }

    private fun Amount.mapToDTOAmount(): AmountDTO {
        return AmountDTO(
            this.currency ?: throw Exception("Currency must not be null"),
            this.value,
        )
    }

    private fun GooglePayConfigurationDTO.mapToGooglePayConfiguration(
        builder: GooglePayConfiguration.Builder,
        analyticsConfiguration: AnalyticsConfiguration? = null,
        amount: Amount? = null,
        countryCode: String? = null
    ): GooglePayConfiguration {
        builder.setGooglePayEnvironment(googlePayEnvironment.mapToWalletConstants())

        analyticsConfiguration?.let {
            builder.setAnalyticsConfiguration(it)
        }

        amount?.let {
            builder.setAmount(it)
        }

        countryCode?.let {
            builder.setCountryCode(it)
        }

        merchantAccount?.let { merchantAccount ->
            builder.setMerchantAccount(merchantAccount)
        }

        merchantInfoDTO?.let {
            builder.setMerchantInfo(it.mapToMerchantInfo())
        }

        totalPriceStatus?.let { totalPriceStatus ->
            builder.setTotalPriceStatus(totalPriceStatus.mapToTotalPriceStatus())
        }

        if (allowedCardNetworks?.isNotEmpty() == true) {
            builder.setAllowedCardNetworks(allowedCardNetworks.filterNotNull())
        }

        if (allowedAuthMethods?.isNotEmpty() == true) {
            builder.setAllowedAuthMethods(allowedAuthMethods.filterNotNull())
        }

        allowPrepaidCards?.let {
            builder.setAllowPrepaidCards(it)
        }

        allowCreditCards?.let {
            builder.setAllowCreditCards(it)
        }

        assuranceDetailsRequired?.let {
            builder.setAssuranceDetailsRequired(it)
        }

        emailRequired?.let {
            builder.setEmailRequired(it)
        }

        existingPaymentMethodRequired?.let {
            builder.setExistingPaymentMethodRequired(it)
        }

        shippingAddressRequired?.let {
            builder.setShippingAddressRequired(it)
        }

        shippingAddressParametersDTO?.let {
            builder.setShippingAddressParameters(it.mapToShippingAddressParameters())
        }

        billingAddressRequired?.let {
            builder.setBillingAddressRequired(it)
        }

        billingAddressParametersDTO?.let {
            builder.setBillingAddressParameters(it.mapToBillingAddressParameters())
        }

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

    private fun MerchantInfoDTO.mapToMerchantInfo(): MerchantInfo {
        return MerchantInfo(merchantName, merchantId)
    }

    private fun ShippingAddressParametersDTO.mapToShippingAddressParameters(): ShippingAddressParameters {
        return when {
            isPhoneNumberRequired != null -> ShippingAddressParameters(allowedCountryCodes, isPhoneNumberRequired)
            else -> ShippingAddressParameters(allowedCountryCodes)
        }
    }

    private fun BillingAddressParametersDTO.mapToBillingAddressParameters(): BillingAddressParameters {
        return when {
            isPhoneNumberRequired != null -> BillingAddressParameters(format, isPhoneNumberRequired)
            else -> BillingAddressParameters(format)
        }
    }

    private fun CashAppPayConfigurationDTO.mapToCashAppPayConfiguration(
        builder: CashAppPayConfiguration.Builder
    ): CashAppPayConfiguration {
        builder.setCashAppPayEnvironment(cashAppPayEnvironment.mapToCashAppPayEnvironment()).setReturnUrl(returnUrl)
        return builder.build()
    }

    private fun CashAppPayEnvironment.mapToCashAppPayEnvironment(): SDKCashAppPayEnvironment {
        return when (this) {
            CashAppPayEnvironment.SANDBOX -> SDKCashAppPayEnvironment.SANDBOX
            CashAppPayEnvironment.PRODUCTION -> SDKCashAppPayEnvironment.PRODUCTION
        }
    }

    fun InstantPaymentConfigurationDTO.mapToGooglePayCheckoutConfiguration(amount: Amount): CheckoutConfiguration {
        return CheckoutConfiguration(
            environment.toNativeModel(),
            clientKey,
            shopperLocale?.let { Locale.forLanguageTag(it) },
            amount,
            analyticsOptionsDTO.mapToAnalyticsConfiguration()
        )
    }

    fun EncryptedCard.mapToEncryptedCardDTO(): EncryptedCardDTO {
        return EncryptedCardDTO(encryptedCardNumber, encryptedExpiryMonth, encryptedExpiryYear, encryptedSecurityCode)
    }

    fun UnencryptedCardDTO.fromDTO(): UnencryptedCard {
        val unencryptedCardBuilder = UnencryptedCard.Builder()
        cardNumber?.let { unencryptedCardBuilder.setNumber(it) }
        if (expiryMonth != null && expiryYear != null) {
            unencryptedCardBuilder.setExpiryDate(expiryMonth, expiryYear)
        }
        cvc?.let { unencryptedCardBuilder.setCvc(it) }
        return unencryptedCardBuilder.build()
    }

    fun InstantPaymentConfigurationDTO.mapToCheckoutConfiguration(): CheckoutConfiguration =
        CheckoutConfiguration(
            environment.toNativeModel(),
            clientKey,
            shopperLocale?.let { Locale.forLanguageTag(it) },
            amount?.toNativeModel(),
            analyticsOptionsDTO.mapToAnalyticsConfiguration(),
        )
}
