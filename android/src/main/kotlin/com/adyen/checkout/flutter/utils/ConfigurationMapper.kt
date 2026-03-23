package com.adyen.checkout.flutter.utils

import com.adyen.checkout.card.FieldMode
import com.adyen.checkout.card.card
import com.adyen.checkout.card.old.AddressConfiguration
import com.adyen.checkout.card.old.InstallmentConfiguration
import com.adyen.checkout.card.old.InstallmentOptions
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.core.common.CardBrand
import com.adyen.checkout.core.common.PaymentResult
import com.adyen.checkout.core.common.internal.helper.CheckoutPlatform
import com.adyen.checkout.core.common.internal.helper.CheckoutPlatformParams
import com.adyen.checkout.core.components.AnalyticsConfiguration
import com.adyen.checkout.core.components.AnalyticsLevel
import com.adyen.checkout.core.components.data.model.Amount
import com.adyen.checkout.core.sessions.SessionResponse
import com.adyen.checkout.cse.EncryptedCard
import com.adyen.checkout.cse.UnencryptedCard
import com.adyen.checkout.flutter.generated.ActionComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.AddressMode
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsOptionsDTO
import com.adyen.checkout.flutter.generated.BillingAddressParametersDTO
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardBasedInstallmentOptionsDTO
import com.adyen.checkout.flutter.generated.CardConfigurationDTO
import com.adyen.checkout.flutter.generated.CashAppPayConfigurationDTO
import com.adyen.checkout.flutter.generated.CashAppPayEnvironment
import com.adyen.checkout.flutter.generated.CheckoutConfigurationDTO
import com.adyen.checkout.flutter.generated.DefaultInstallmentOptionsDTO
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.Environment
import com.adyen.checkout.flutter.generated.FieldVisibility
import com.adyen.checkout.flutter.generated.GooglePayConfigurationDTO
import com.adyen.checkout.flutter.generated.GooglePayEnvironment
import com.adyen.checkout.flutter.generated.InstallmentConfigurationDTO
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.MerchantInfoDTO
import com.adyen.checkout.flutter.generated.OrderResponseDTO
import com.adyen.checkout.flutter.generated.SessionResponseDTO
import com.adyen.checkout.flutter.generated.ShippingAddressParametersDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ButtonCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ConfigurationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2InputCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2LabelCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2SelectionItemCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ToolbarCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2UICustomizationDTO
import com.adyen.checkout.flutter.generated.TotalPriceStatus
import com.adyen.checkout.flutter.generated.TwintConfigurationDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.googlepay.old.BillingAddressParameters
import com.adyen.checkout.googlepay.old.MerchantInfo
import com.adyen.checkout.googlepay.old.ShippingAddressParameters
import com.google.android.gms.wallet.WalletConstants
import com.adyen.threeds2.customization.ButtonCustomization
import com.adyen.threeds2.customization.LabelCustomization
import com.adyen.threeds2.customization.TextBoxCustomization
import com.adyen.threeds2.customization.SelectionItemCustomization
import com.adyen.threeds2.customization.ToolbarCustomization
import com.adyen.threeds2.customization.UiCustomization
import java.util.Locale
import com.adyen.checkout.cashapppay.CashAppPayEnvironment as SDKCashAppPayEnvironment
import com.adyen.checkout.core.common.Environment as SDKEnvironment
import com.adyen.checkout.core.components.CheckoutConfiguration
import com.adyen.checkout.flutter.generated.PaymentResultModelDTO

object ConfigurationMapper {
    fun CheckoutConfigurationDTO.toCheckoutConfiguration(): CheckoutConfiguration =
        toCheckoutConfiguration(
            environment = environment,
            clientKey = clientKey,
            analyticsOptionsDTO = analyticsOptionsDTO,
            shopperLocale = shopperLocale,
            amount = amount,
            countryCode = countryCode,
            cardConfigurationDTO = cardConfigurationDTO,
            googlePayConfigurationDTO = googlePayConfigurationDTO,
            cashAppPayConfigurationDTO = cashAppPayConfigurationDTO,
            threeDS2ConfigurationDTO = threeDS2ConfigurationDTO,
            twintConfigurationDTO = twintConfigurationDTO,
        )

    fun OrderResponse.mapToOrderResponseModel(): OrderResponseDTO =
        OrderResponseDTO(
            pspReference = pspReference,
            orderData = orderData,
            amount = amount?.mapToDTOAmount(),
            remainingAmount = remainingAmount?.mapToDTOAmount(),
        )

    fun DropInConfigurationDTO.toCheckoutConfiguration(): CheckoutConfiguration =
        toCheckoutConfiguration(
            environment = environment,
            clientKey = clientKey,
            analyticsOptionsDTO = analyticsOptionsDTO,
            shopperLocale = shopperLocale,
            amount = amount,
            countryCode = countryCode,
            cardConfigurationDTO = cardConfigurationDTO,
            googlePayConfigurationDTO = googlePayConfigurationDTO,
            cashAppPayConfigurationDTO = cashAppPayConfigurationDTO,
            twintConfigurationDTO = twintConfigurationDTO,
            threeDS2ConfigurationDTO = threeDS2ConfigurationDTO,
        ).apply {
//            dropIn {
//                isRemovingStoredPaymentMethodsEnabled = this@toCheckoutConfiguration.isRemoveStoredPaymentMethodEnabled
//                showPreselectedStoredPaymentMethod = this@toCheckoutConfiguration.showPreselectedStoredPaymentMethod
//                skipListWhenSinglePaymentMethod = this@toCheckoutConfiguration.skipListWhenSinglePaymentMethod
//                paymentMethodNames?.forEach { (paymentMethodType, paymentMethodName) ->
//                    if (paymentMethodType != null && paymentMethodName != null) {
//                        overridePaymentMethodName(paymentMethodType, paymentMethodName)
//                    }
//                }
//            }
        }

    fun CardComponentConfigurationDTO.toCheckoutConfiguration(): CheckoutConfiguration =
        toCheckoutConfiguration(
            environment = environment,
            clientKey = clientKey,
            analyticsOptionsDTO = analyticsOptionsDTO,
            shopperLocale = shopperLocale,
            amount = amount,
            countryCode = countryCode,
            cardConfigurationDTO = cardConfiguration,
            threeDS2ConfigurationDTO = threeDS2ConfigurationDTO,
        )

    fun ActionComponentConfigurationDTO.toCheckoutConfiguration(): CheckoutConfiguration =
        toCheckoutConfiguration(
            environment = environment,
            clientKey = clientKey,
            analyticsOptionsDTO = analyticsOptionsDTO,
            shopperLocale = shopperLocale,
            amount = amount,
        )

    fun InstantPaymentConfigurationDTO.toCheckoutConfiguration(): CheckoutConfiguration =
        toCheckoutConfiguration(
            environment = environment,
            clientKey = clientKey,
            analyticsOptionsDTO = analyticsOptionsDTO,
            shopperLocale = shopperLocale,
            amount = amount,
            countryCode = countryCode,
            googlePayConfigurationDTO = googlePayConfigurationDTO,
        )

    private fun toCheckoutConfiguration(
        environment: Environment,
        clientKey: String,
        analyticsOptionsDTO: AnalyticsOptionsDTO,
        shopperLocale: String? = null,
        amount: AmountDTO? = null,
        countryCode: String? = null,
        cardConfigurationDTO: CardConfigurationDTO? = null,
        googlePayConfigurationDTO: GooglePayConfigurationDTO? = null,
        cashAppPayConfigurationDTO: CashAppPayConfigurationDTO? = null,
        twintConfigurationDTO: TwintConfigurationDTO? = null,
        threeDS2ConfigurationDTO: ThreeDS2ConfigurationDTO? = null,
    ): CheckoutConfiguration {
        val sdkEnvironment = environment.mapToEnvironment()
        val sdkAmount = amount?.mapToAmount()
        val analyticsConfiguration = analyticsOptionsDTO.mapToAnalyticsConfiguration()

        return CheckoutConfiguration(
            environment = sdkEnvironment,
            clientKey = clientKey,
            shopperLocale = shopperLocale?.let { Locale.forLanguageTag(it) },
            amount = sdkAmount,
            analyticsConfiguration = analyticsConfiguration,
        ).apply {
            cardConfigurationDTO?.let { configurationDTO ->
                card {
                    supportedCardBrands = mapToSupportedCardBrands(configurationDTO.supportedCardTypes)
                    showHolderName = configurationDTO.holderNameRequired
                    showStorePayment = configurationDTO.showStorePaymentField
                    hideSecurityCode = !configurationDTO.showCvc
                    hideStoredSecurityCode = !configurationDTO.showCvcForStoredCard
                    koreanAuthenticationMode = determineFieldVisibility(configurationDTO.kcpFieldVisibility)
                    socialSecurityNumberMode =
                        determineFieldVisibility(configurationDTO.socialSecurityNumberFieldVisibility)
//                    addressConfiguration = configurationDTO.addressMode.mapToAddressConfiguration()
                }
            }

            threeDS2ConfigurationDTO?.let { configurationDTO ->
//                adyen3DS2 {
//                    threeDSRequestorAppURL = configurationDTO.requestorAppURL
//                }
            }

            googlePayConfigurationDTO?.let { configurationDTO ->
//                googlePay {
//                    googlePayEnvironment = configurationDTO.googlePayEnvironment.mapToWalletConstants()
//                    this.countryCode = countryCode
//                    merchantAccount = configurationDTO.merchantAccount
//                    merchantInfo = configurationDTO.merchantInfoDTO?.mapToMerchantInfo()
//                    totalPriceStatus = configurationDTO.totalPriceStatus?.mapToTotalPriceStatus()
//                    configurationDTO.allowedCardNetworks?.let { allowedCardNetworks = it.filterNotNull() }
//                    configurationDTO.allowedAuthMethods?.let { allowedAuthMethods = it.filterNotNull() }
//                    configurationDTO.allowPrepaidCards?.let { isAllowPrepaidCards = it }
//                    configurationDTO.allowCreditCards?.let { isAllowCreditCards = it }
//                    configurationDTO.assuranceDetailsRequired?.let { isAssuranceDetailsRequired = it }
//                    configurationDTO.emailRequired?.let { isEmailRequired = it }
//                    configurationDTO.existingPaymentMethodRequired?.let { isExistingPaymentMethodRequired = it }
//                    configurationDTO.shippingAddressRequired?.let { isShippingAddressRequired = it }
//                    shippingAddressParameters =
//                        configurationDTO.shippingAddressParametersDTO?.mapToShippingAddressParameters()
//                    configurationDTO.billingAddressRequired?.let { isBillingAddressRequired = it }
//                    billingAddressParameters =
//                        configurationDTO.billingAddressParametersDTO?.mapToBillingAddressParameters()
//                }
            }

            cashAppPayConfigurationDTO?.let { configurationDTO ->
//                cashAppPay {
//                    cashAppPayEnvironment = configurationDTO.cashAppPayEnvironment.mapToCashAppPayEnvironment()
//                    returnUrl = configurationDTO.returnUrl
//                }
            }

            twintConfigurationDTO?.let { configurationDTO ->
//                twint {
//                    showStorePaymentField = configurationDTO.showStorePaymentField
//                }
            }
        }
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

    fun Environment.mapToEnvironment(): SDKEnvironment =
        when (this) {
            Environment.TEST -> SDKEnvironment.TEST
            Environment.LIVE_EUROPE -> SDKEnvironment.LIVE_EUROPE
            Environment.LIVE_UNITED_STATES -> SDKEnvironment.LIVE_UNITED_STATES
            Environment.LIVE_AUSTRALIA -> SDKEnvironment.LIVE_AUSTRALIA
            Environment.LIVE_APSE -> SDKEnvironment.LIVE_APSE
            Environment.LIVE_INDIA -> SDKEnvironment.LIVE_INDIA
            Environment.LIVE_NEA -> SDKEnvironment.LIVE_NEA
        }

    private fun AnalyticsOptionsDTO.mapToAnalyticsConfiguration(): AnalyticsConfiguration {
        val analyticsLevel =
            when {
                enabled -> AnalyticsLevel.ALL
                else -> AnalyticsLevel.NONE
            }
        CheckoutPlatformParams.overrideForCrossPlatform(CheckoutPlatform.FLUTTER, version)
        return AnalyticsConfiguration(analyticsLevel)
    }

    private fun AddressMode.mapToAddressConfiguration(): AddressConfiguration =
        when (this) {
            AddressMode.FULL -> AddressConfiguration.FullAddress()
            AddressMode.POSTAL_CODE -> AddressConfiguration.PostalCode()
            AddressMode.NONE -> AddressConfiguration.None
        }

    fun determineFieldVisibility(fieldVisibility: FieldVisibility): FieldMode =
        when (fieldVisibility) {
            FieldVisibility.SHOW -> FieldMode.SHOW
            FieldVisibility.HIDE -> FieldMode.HIDE
        }

    private fun mapToSupportedCardBrands(cardTypes: List<String?>?): List<CardBrand> =
        cardTypes.orEmpty().filterNotNull().map(::CardBrand)

    fun AmountDTO.mapToAmount(): Amount = Amount(this.currency, this.value)

    fun SessionResponseDTO.mapToSessionResponse(): SessionResponse = SessionResponse(id, sessionData)

    fun PaymentResult.mapToPaymentResultModelDTO(): PaymentResultModelDTO =
        PaymentResultModelDTO(sessionId, sessionResult, resultCode)

    private fun com.adyen.checkout.components.core.Amount.mapToDTOAmount(): AmountDTO =
        AmountDTO(
            this.currency ?: throw IllegalStateException("Currency must not be null"),
            this.value,
        )

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

    private fun CashAppPayEnvironment.mapToCashAppPayEnvironment(): SDKCashAppPayEnvironment =
        when (this) {
            CashAppPayEnvironment.SANDBOX -> SDKCashAppPayEnvironment.SANDBOX
            CashAppPayEnvironment.PRODUCTION -> SDKCashAppPayEnvironment.PRODUCTION
        }

    private fun ThreeDS2UICustomizationDTO.toUiCustomization(): UiCustomization =
        UiCustomization().apply {
            this@toUiCustomization.screenCustomization?.let { dto ->
                dto.backgroundColor?.let { setScreenBackgroundColor(it) }
                dto.textColor?.let { setTextColor(it) }
            }

            this@toUiCustomization.headingCustomization?.let { dto ->
                toolbarCustomization = dto.toToolbarCustomization()
            }

            this@toUiCustomization.labelCustomization?.let { dto ->
                labelCustomization = dto.toLabelCustomization()
            }

            this@toUiCustomization.inputCustomization?.let { dto ->
                textBoxCustomization = dto.toTextBoxCustomization()
            }

            this@toUiCustomization.selectionItemCustomization?.let { dto ->
                selectionItemCustomization = dto.toSelectionItemCustomization()
            }

            this@toUiCustomization.primaryButtonCustomization?.let { dto ->
                val buttonCustomization = dto.toButtonCustomization()
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.VERIFY)
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.CONTINUE)
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.NEXT)
            }

            this@toUiCustomization.secondaryButtonCustomization?.let { dto ->
                val buttonCustomization = dto.toButtonCustomization()
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.CANCEL)
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.RESEND)
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.OPEN_OOB_APP)
            }
        }

    private fun ThreeDS2ToolbarCustomizationDTO.toToolbarCustomization(): ToolbarCustomization =
        ToolbarCustomization().apply {
            this@toToolbarCustomization.textColor?.let { textColor = it }
            this@toToolbarCustomization.backgroundColor?.let { backgroundColor = it }
            this@toToolbarCustomization.headerText?.let { headerText = it }
        }

    private fun ThreeDS2LabelCustomizationDTO.toLabelCustomization(): LabelCustomization =
        LabelCustomization().apply {
            this@toLabelCustomization.headingTextColor?.let { headingTextColor = it }
            this@toLabelCustomization.headingTextFontSize?.let { headingTextFontSize = it.toInt() }
            this@toLabelCustomization.textColor?.let { textColor = it }
            this@toLabelCustomization.textFontSize?.let { textFontSize = it.toInt() }
            this@toLabelCustomization.inputLabelTextColor?.let { inputLabelTextColor = it }
            this@toLabelCustomization.inputLabelFontSize?.let { inputLabelTextFontSize = it.toInt() }
        }

    private fun ThreeDS2InputCustomizationDTO.toTextBoxCustomization(): TextBoxCustomization =
        TextBoxCustomization().apply {
            this@toTextBoxCustomization.borderColor?.let { borderColor = it }
            this@toTextBoxCustomization.borderWidth?.let { borderWidth = it.toInt() }
            this@toTextBoxCustomization.cornerRadius?.let { cornerRadius = it.toInt() }
            this@toTextBoxCustomization.textColor?.let { textColor = it }
        }

    private fun ThreeDS2SelectionItemCustomizationDTO.toSelectionItemCustomization(): SelectionItemCustomization =
        SelectionItemCustomization().apply {
            this@toSelectionItemCustomization.selectionIndicatorTintColor?.let { selectionIndicatorTintColor = it }
            this@toSelectionItemCustomization.highlightedBackgroundColor?.let { highlightedBackgroundColor = it }
            this@toSelectionItemCustomization.textColor?.let { textColor = it }
        }

    private fun ThreeDS2ButtonCustomizationDTO.toButtonCustomization(): ButtonCustomization =
        ButtonCustomization().apply {
            this@toButtonCustomization.backgroundColor?.let { backgroundColor = it }
            this@toButtonCustomization.cornerRadius?.let { cornerRadius = it.toInt() }
            this@toButtonCustomization.textColor?.let { textColor = it }
            this@toButtonCustomization.textFontSize?.let { textFontSize = it.toInt() }
        }

    private fun InstallmentConfigurationDTO.mapToInstallmentConfiguration(): InstallmentConfiguration {
        val defaultOptions = defaultOptions?.mapToDefaultInstallmentOptions()
        val cardBasedOptions = cardBasedOptions?.mapNotNull { it?.mapToCardBasedInstallmentOptions() } ?: emptyList()

        return InstallmentConfiguration(
            defaultOptions = defaultOptions,
            cardBasedOptions = cardBasedOptions,
            showInstallmentAmount = showInstallmentAmount
        )
    }

    private fun DefaultInstallmentOptionsDTO.mapToDefaultInstallmentOptions():
        InstallmentOptions.DefaultInstallmentOptions =
        InstallmentOptions.DefaultInstallmentOptions(
            values = (values as List<Number?>).mapNotNull { it?.toInt() },
            includeRevolving = includesRevolving
        )

    private fun CardBasedInstallmentOptionsDTO.mapToCardBasedInstallmentOptions():
        InstallmentOptions.CardBasedInstallmentOptions =
        InstallmentOptions.CardBasedInstallmentOptions(
            values = (values as List<Number?>).mapNotNull { it?.toInt() },
            includeRevolving = includesRevolving,
            cardBrand =
                com.adyen.checkout.core.old
                    .CardBrand(txVariant = cardBrand)
        )
}
