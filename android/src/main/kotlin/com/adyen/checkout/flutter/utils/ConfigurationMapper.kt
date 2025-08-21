package com.adyen.checkout.flutter.utils

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
import com.adyen.checkout.flutter.generated.ActionComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.AddressMode
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsOptionsDTO
import com.adyen.checkout.flutter.generated.BillingAddressParametersDTO
import com.adyen.checkout.flutter.generated.CardConfigurationDTO
import com.adyen.checkout.flutter.generated.CashAppPayConfigurationDTO
import com.adyen.checkout.flutter.generated.CashAppPayEnvironment
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.Environment
import com.adyen.checkout.flutter.generated.FieldVisibility
import com.adyen.checkout.flutter.generated.GooglePayConfigurationDTO
import com.adyen.checkout.flutter.generated.GooglePayEnvironment
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.MerchantInfoDTO
import com.adyen.checkout.flutter.generated.OrderResponseDTO
import com.adyen.checkout.flutter.generated.ShippingAddressParametersDTO
import com.adyen.checkout.flutter.generated.TotalPriceStatus
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.googlepay.BillingAddressParameters
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.googlepay.MerchantInfo
import com.adyen.checkout.googlepay.ShippingAddressParameters
import com.adyen.checkout.googlepay.googlePay
import com.google.android.gms.wallet.WalletConstants
import java.util.Locale
import com.adyen.checkout.cashapppay.CashAppPayEnvironment as SDKCashAppPayEnvironment
import com.adyen.checkout.core.Environment as SDKEnvironment

object ConfigurationMapper {
    fun OrderResponse.mapToOrderResponseModel(): OrderResponseDTO =
        OrderResponseDTO(
            pspReference = pspReference,
            orderData = orderData,
            amount = amount?.mapToDTOAmount(),
            remainingAmount = remainingAmount?.mapToDTOAmount(),
        )

    fun DropInConfigurationDTO.mapToDropInConfiguration(context: Context): DropInConfiguration {
        val environment = environment.mapToEnvironment()
        val amount = amount?.mapToAmount()
        val dropInConfiguration = buildDropInConfiguration(context, shopperLocale, environment)
        val analyticsConfiguration = analyticsOptionsDTO.mapToAnalyticsConfiguration()
        dropInConfiguration.apply {
            setAnalyticsConfiguration(analyticsConfiguration)
            setEnableRemovingStoredPaymentMethods(isRemoveStoredPaymentMethodEnabled)
            showPreselectedStoredPaymentMethod?.let { setShowPreselectedStoredPaymentMethod(it) }
            skipListWhenSinglePaymentMethod?.let { setSkipListWhenSinglePaymentMethod(it) }
            amount?.let {
                setAmount(it)
            }
        }

        if (cardConfigurationDTO != null) {
            val cardConfiguration =
                cardConfigurationDTO.mapToCardConfiguration(
                    context = context,
                    shopperLocale = shopperLocale,
                    environment = environment,
                    clientKey = clientKey,
                    amount = amount,
                )
            dropInConfiguration.addCardConfiguration(cardConfiguration)
        }

        if (googlePayConfigurationDTO != null) {
            val googlePayConfiguration =
                buildGooglePayConfiguration(clientKey, shopperLocale, environment, googlePayConfigurationDTO)
            dropInConfiguration.addGooglePayConfiguration(googlePayConfiguration)
        }

        if (cashAppPayConfigurationDTO != null) {
            val cashAppPayConfiguration =
                buildCashAppPayConfiguration(context, shopperLocale, environment, cashAppPayConfigurationDTO)
            dropInConfiguration.addCashAppPayConfiguration(cashAppPayConfiguration)
        }

        paymentMethodNames?.forEach { paymentMethodNamePair ->
            val paymentMethodType = paymentMethodNamePair.key
            val paymentMethodName = paymentMethodNamePair.value
            if (paymentMethodType != null && paymentMethodName != null) {
                dropInConfiguration.overridePaymentMethodName(paymentMethodType, paymentMethodName)
            }
        }

        return dropInConfiguration.build()
    }

    private fun DropInConfigurationDTO.buildDropInConfiguration(
        context: Context,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
    ): DropInConfiguration.Builder =
        if (shopperLocale != null) {
            val locale = Locale.forLanguageTag(shopperLocale)
            DropInConfiguration.Builder(locale, environment, clientKey)
        } else {
            DropInConfiguration.Builder(context, environment, clientKey)
        }

    fun CardConfigurationDTO.mapToCardConfiguration(
        context: Context,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
        clientKey: String,
        analyticsConfiguration: AnalyticsConfiguration? = null,
        amount: Amount? = null,
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
            .setShowStorePaymentField(showStorePaymentField)
            .setHideCvcStoredCard(!showCvcForStoredCard)
            .setHideCvc(!showCvc)
            .setKcpAuthVisibility(determineKcpAuthVisibility(kcpFieldVisibility))
            .setSocialSecurityNumberVisibility(
                determineSocialSecurityNumberVisibility(socialSecurityNumberFieldVisibility)
            ).setSupportedCardTypes(*mapToSupportedCardTypes(supportedCardTypes))
            .setHolderNameRequired(holderNameRequired)

        analyticsConfiguration?.let {
            cardConfiguration.setAnalyticsConfiguration(it)
        }
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

    private fun buildGooglePayConfiguration(
        clientKey: String,
        shopperLocale: String?,
        environment: com.adyen.checkout.core.Environment,
        googlePayConfigurationDTO: GooglePayConfigurationDTO
    ): GooglePayConfiguration {
        val googlePayConfigurationBuilder =
            if (shopperLocale != null) {
                val locale = Locale.forLanguageTag(shopperLocale)
                GooglePayConfiguration.Builder(locale, environment, clientKey)
            } else {
                GooglePayConfiguration.Builder(environment, clientKey)
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

    private fun AddressMode.mapToAddressConfiguration(): AddressConfiguration =
        when (this) {
            AddressMode.FULL -> AddressConfiguration.FullAddress()
            AddressMode.POSTAL_CODE -> AddressConfiguration.PostalCode()
            AddressMode.NONE -> AddressConfiguration.None
        }

    private fun determineKcpAuthVisibility(fieldVisibility: FieldVisibility): KCPAuthVisibility =
        when (fieldVisibility) {
            FieldVisibility.SHOW -> KCPAuthVisibility.SHOW
            FieldVisibility.HIDE -> KCPAuthVisibility.HIDE
        }

    private fun determineSocialSecurityNumberVisibility(visible: FieldVisibility): SocialSecurityNumberVisibility =
        when (visible) {
            FieldVisibility.SHOW -> SocialSecurityNumberVisibility.SHOW
            FieldVisibility.HIDE -> SocialSecurityNumberVisibility.HIDE
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

    fun Environment.mapToEnvironment(): SDKEnvironment =
        when (this) {
            Environment.TEST -> SDKEnvironment.TEST
            Environment.EUROPE -> SDKEnvironment.EUROPE
            Environment.UNITED_STATES -> SDKEnvironment.UNITED_STATES
            Environment.AUSTRALIA -> SDKEnvironment.AUSTRALIA
            Environment.INDIA -> SDKEnvironment.INDIA
            Environment.APSE -> SDKEnvironment.APSE
        }

    fun AmountDTO.mapToAmount(): Amount = Amount(this.currency, this.value)

    private fun Amount.mapToDTOAmount(): AmountDTO =
        AmountDTO(
            this.currency ?: throw Exception("Currency must not be null"),
            this.value,
        )

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

    private fun GooglePayEnvironment.mapToWalletConstants(): Int =
        when (this) {
            GooglePayEnvironment.TEST -> WalletConstants.ENVIRONMENT_TEST
            GooglePayEnvironment.PRODUCTION -> WalletConstants.ENVIRONMENT_PRODUCTION
        }

    private fun TotalPriceStatus.mapToTotalPriceStatus(): String =
        when (this) {
            TotalPriceStatus.NOT_CURRENTLY_KNOWN -> "NOT_CURRENTLY_KNOWN"
            TotalPriceStatus.ESTIMATED -> "ESTIMATED"
            TotalPriceStatus.FINAL_PRICE -> "FINAL"
        }

    private fun MerchantInfoDTO.mapToMerchantInfo(): MerchantInfo = MerchantInfo(merchantName, merchantId)

    private fun ShippingAddressParametersDTO.mapToShippingAddressParameters(): ShippingAddressParameters =
        when {
            isPhoneNumberRequired != null -> ShippingAddressParameters(allowedCountryCodes, isPhoneNumberRequired)
            else -> ShippingAddressParameters(allowedCountryCodes)
        }

    private fun BillingAddressParametersDTO.mapToBillingAddressParameters(): BillingAddressParameters =
        when {
            isPhoneNumberRequired != null -> BillingAddressParameters(format, isPhoneNumberRequired)
            else -> BillingAddressParameters(format)
        }

    private fun CashAppPayConfigurationDTO.mapToCashAppPayConfiguration(
        builder: CashAppPayConfiguration.Builder
    ): CashAppPayConfiguration {
        builder.setCashAppPayEnvironment(cashAppPayEnvironment.mapToCashAppPayEnvironment()).setReturnUrl(returnUrl)
        return builder.build()
    }

    private fun CashAppPayEnvironment.mapToCashAppPayEnvironment(): SDKCashAppPayEnvironment =
        when (this) {
            CashAppPayEnvironment.SANDBOX -> SDKCashAppPayEnvironment.SANDBOX
            CashAppPayEnvironment.PRODUCTION -> SDKCashAppPayEnvironment.PRODUCTION
        }

    fun EncryptedCard.mapToEncryptedCardDTO(): EncryptedCardDTO =
        EncryptedCardDTO(encryptedCardNumber, encryptedExpiryMonth, encryptedExpiryYear, encryptedSecurityCode)

    fun UnencryptedCardDTO.fromDTO(): UnencryptedCard {
        val unencryptedCardBuilder = UnencryptedCard.Builder()
        cardNumber?.let { unencryptedCardBuilder.setNumber(it) }
        if (expiryMonth != null && expiryYear != null) {
            unencryptedCardBuilder.setExpiryDate(expiryMonth, expiryYear)
        }
        cvc?.let { unencryptedCardBuilder.setCvc(it) }
        return unencryptedCardBuilder.build()
    }

    fun InstantPaymentConfigurationDTO.mapToGooglePayCheckoutConfiguration(): CheckoutConfiguration =
        mapToCheckoutConfiguration().googlePay {
            googlePayConfigurationDTO?.mapToGooglePayConfiguration(this, countryCode = countryCode)
        }

    fun InstantPaymentConfigurationDTO.mapToCheckoutConfiguration(): CheckoutConfiguration =
        CheckoutConfiguration(
            environment.mapToEnvironment(),
            clientKey,
            shopperLocale?.let { Locale.forLanguageTag(it) },
            amount?.mapToAmount(),
            analyticsOptionsDTO.mapToAnalyticsConfiguration(),
        )

    fun ActionComponentConfigurationDTO.mapToCheckoutConfiguration(): CheckoutConfiguration =
        CheckoutConfiguration(
            environment.mapToEnvironment(),
            clientKey,
            shopperLocale?.let { Locale.forLanguageTag(it) },
            amount?.mapToAmount(),
            analyticsOptionsDTO.mapToAnalyticsConfiguration(),
        )
}
