package com.adyen.checkout.flutter.utils

import com.adyen.checkout.card.BillingAddressMode
import com.adyen.checkout.card.FieldVisibility as SdkFieldVisibility
import com.adyen.checkout.card.InstallmentConfiguration
import com.adyen.checkout.card.InstallmentOptions
import com.adyen.checkout.card.card
import com.adyen.checkout.core.common.CardBrand
import com.adyen.checkout.core.common.Environment as SdkEnvironment
import com.adyen.checkout.core.components.AnalyticsConfiguration
import com.adyen.checkout.core.components.AnalyticsLevel
import com.adyen.checkout.core.components.CheckoutConfiguration
import com.adyen.checkout.core.components.data.model.Amount
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsConfigurationDTO
import com.adyen.checkout.flutter.generated.BillingAddressModeDTO
import com.adyen.checkout.flutter.generated.CardConfigurationDTO
import com.adyen.checkout.flutter.generated.CheckoutConfigurationDTO
import com.adyen.checkout.flutter.generated.EnvironmentDTO
import com.adyen.checkout.flutter.generated.FieldVisibilityDTO
import com.adyen.checkout.flutter.generated.GooglePayConfigurationDTO
import com.adyen.checkout.flutter.generated.GooglePayEnvironmentDTO
import com.adyen.checkout.flutter.generated.InstallmentConfigurationDTO
import com.adyen.checkout.flutter.generated.InstallmentOptionsDTO
import com.adyen.checkout.flutter.generated.MerchantInfoDTO
import com.adyen.checkout.flutter.generated.ShippingAddressParametersDTO
import com.adyen.checkout.flutter.generated.TotalPriceStatusDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.cse.UnencryptedCard
import com.adyen.checkout.googlepay.MerchantInfo
import com.adyen.checkout.googlepay.ShippingAddressParameters
import com.adyen.checkout.googlepay.googlePay
import com.google.android.gms.wallet.WalletConstants

object ConfigurationMapper {
    fun CheckoutConfigurationDTO.toCheckoutConfiguration(): CheckoutConfiguration {
        val countryCode = countryCode?.trim()?.uppercase()
        if (googlePayConfiguration != null && countryCode.isNullOrEmpty()) {
            throw IllegalArgumentException("countryCode is required when Google Pay is configured.")
        }

        return CheckoutConfiguration(
            environment = environment.toNativeEnvironment(),
            clientKey = clientKey,
            amount = amount?.toNativeAmount(),
            analyticsConfiguration = analyticsConfiguration.toNativeAnalyticsConfiguration(),
            showSubmitButton = showSubmitButton,
        ).apply {
            cardConfiguration?.let { configuration ->
                card(
                    billingAddressMode = configuration.billingAddressMode.toNativeBillingAddressMode(),
                    koreanAuthenticationVisibility = configuration.koreanAuthenticationVisibility.toNativeFieldVisibility(),
                    showCardholderName = configuration.showCardholderName,
                    showSecurityCode = configuration.showSecurityCode,
                    showSecurityCodeForStoredCard = configuration.showSecurityCodeForStoredCard,
                    showStorePaymentMethod = configuration.showStorePaymentMethod,
                    showSupportedCardBrandLogos = configuration.showSupportedCardBrandLogos,
                    socialSecurityNumberVisibility = configuration.socialSecurityNumberVisibility.toNativeFieldVisibility(),
                    supportedCardBrands = configuration.supportedCardBrands
                        ?.map(::CardBrand),
                    installmentConfiguration = configuration.installmentConfiguration?.toNativeInstallmentConfiguration(),
                )
            }
            googlePayConfiguration?.let { configuration ->
                googlePay(
                    merchantAccount = configuration.merchantAccount,
                    googlePayEnvironment = configuration.googlePayEnvironment.toWalletEnvironment(),
                    totalPriceStatus = configuration.totalPriceStatus?.toTotalPriceStatus(),
                    countryCode = countryCode,
                    merchantInfo = configuration.merchantInfo?.toNativeMerchantInfo(),
                    isEmailRequired = configuration.emailRequired,
                    isExistingPaymentMethodRequired = configuration.existingPaymentMethodRequired,
                    isShippingAddressRequired = configuration.shippingAddressRequired,
                    shippingAddressParameters = configuration.shippingAddressParameters?.toNativeShippingAddressParameters(),
                )
            }
        }
    }

    private fun EnvironmentDTO.toNativeEnvironment(): SdkEnvironment = when (this) {
        EnvironmentDTO.TEST -> SdkEnvironment.TEST
        EnvironmentDTO.LIVE_EUROPE -> SdkEnvironment.LIVE_EUROPE
        EnvironmentDTO.LIVE_UNITED_STATES -> SdkEnvironment.LIVE_UNITED_STATES
        EnvironmentDTO.LIVE_AUSTRALIA -> SdkEnvironment.LIVE_AUSTRALIA
        EnvironmentDTO.LIVE_APSE -> SdkEnvironment.LIVE_APSE
        EnvironmentDTO.LIVE_INDIA -> SdkEnvironment.LIVE_INDIA
        EnvironmentDTO.LIVE_NEA -> SdkEnvironment.LIVE_NEA
    }

    private fun AmountDTO.toNativeAmount(): Amount = Amount(
        currency = currency,
        value = value.toLong(),
    )

    private fun AnalyticsConfigurationDTO.toNativeAnalyticsConfiguration(): AnalyticsConfiguration =
        AnalyticsConfiguration(
            level = if (enabled) AnalyticsLevel.ALL else AnalyticsLevel.NONE,
        )

    private fun BillingAddressModeDTO.toNativeBillingAddressMode(): BillingAddressMode = when (this) {
        BillingAddressModeDTO.NONE -> BillingAddressMode.None()
        BillingAddressModeDTO.POSTAL_CODE -> BillingAddressMode.PostalCode()
    }

    private fun FieldVisibilityDTO.toNativeFieldVisibility(): SdkFieldVisibility? = when (this) {
        FieldVisibilityDTO.SHOW -> SdkFieldVisibility.SHOW
        FieldVisibilityDTO.HIDE -> SdkFieldVisibility.HIDE
        FieldVisibilityDTO.AUTO -> null
    }

    private fun InstallmentConfigurationDTO.toNativeInstallmentConfiguration(): InstallmentConfiguration? {
        if (options.isEmpty()) return null
        val defaultOptions = options.firstOrNull { it.cardBrand == null }?.toNativeInstallmentOptions()
        val cardBasedOptions = options.mapNotNull { option ->
            option.cardBrand?.let { brand ->
                CardBrand(brand) to option.toNativeInstallmentOptions()
            }
        }.toMap()
        return InstallmentConfiguration(
            defaultOptions = defaultOptions,
            cardBasedOptions = cardBasedOptions,
            showInstallmentAmount = showInstallmentAmount,
        )
    }

    private fun InstallmentOptionsDTO.toNativeInstallmentOptions(): InstallmentOptions =
        InstallmentOptions(
            values = values.map { it.toInt() },
            plans = if (includesRevolving) {
                listOf(InstallmentOptions.Plan.REGULAR, InstallmentOptions.Plan.REVOLVING)
            } else {
                listOf(InstallmentOptions.Plan.REGULAR)
            },
            preselectedValue = null,
        )

    private fun GooglePayEnvironmentDTO.toWalletEnvironment(): Int = when (this) {
        GooglePayEnvironmentDTO.TEST -> WalletConstants.ENVIRONMENT_TEST
        GooglePayEnvironmentDTO.PRODUCTION -> WalletConstants.ENVIRONMENT_PRODUCTION
    }

    private fun TotalPriceStatusDTO.toTotalPriceStatus(): String = when (this) {
        TotalPriceStatusDTO.NOT_CURRENTLY_KNOWN -> "NOT_CURRENTLY_KNOWN"
        TotalPriceStatusDTO.ESTIMATED -> "ESTIMATED"
        TotalPriceStatusDTO.FINAL_PRICE -> "FINAL"
    }

    private fun MerchantInfoDTO.toNativeMerchantInfo(): MerchantInfo = MerchantInfo(
        merchantName = merchantName,
        merchantId = merchantId,
        softwareInfo = null,
    )

    private fun ShippingAddressParametersDTO.toNativeShippingAddressParameters(): ShippingAddressParameters =
        ShippingAddressParameters(
            allowedCountryCodes = allowedCountryCodes,
            isPhoneNumberRequired = isPhoneNumberRequired,
        )

    fun UnencryptedCardDTO.toNativeUnencryptedCard(): UnencryptedCard {
        val builder = UnencryptedCard.Builder()
        cardNumber?.let(builder::setNumber)
        if (expiryMonth != null && expiryYear != null) {
            builder.setExpiryDate(expiryMonth!!, expiryYear!!)
        }
        cvc?.let(builder::setCvc)
        return builder.build()
    }
}
