package com.adyen.checkout.flutter.utils

import com.adyen.checkout.adyen3ds2.adyen3DS2
import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.CardBrand
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.card.card
import com.adyen.checkout.cashapppay.cashAppPay
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.AnalyticsConfiguration
import com.adyen.checkout.components.core.AnalyticsLevel
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.components.core.internal.util.CheckoutPlatform
import com.adyen.checkout.components.core.internal.util.CheckoutPlatformParams
import com.adyen.checkout.cse.EncryptedCard
import com.adyen.checkout.cse.UnencryptedCard
import com.adyen.checkout.dropin.dropIn
import com.adyen.checkout.flutter.generated.ActionComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.AddressMode
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsOptionsDTO
import com.adyen.checkout.flutter.generated.BillingAddressParametersDTO
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
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
import com.adyen.checkout.googlepay.BillingAddressParameters
import com.adyen.checkout.googlepay.MerchantInfo
import com.adyen.checkout.googlepay.ShippingAddressParameters
import com.adyen.checkout.googlepay.googlePay
import com.adyen.checkout.twint.twint
import com.google.android.gms.wallet.WalletConstants
import com.adyen.threeds2.customization.ButtonCustomization
import com.adyen.threeds2.customization.LabelCustomization
import com.adyen.threeds2.customization.TextBoxCustomization
import com.adyen.threeds2.customization.SelectionItemCustomization
import com.adyen.threeds2.customization.ToolbarCustomization
import com.adyen.threeds2.customization.UiCustomization
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
            dropIn {
                isRemovingStoredPaymentMethodsEnabled = this@toCheckoutConfiguration.isRemoveStoredPaymentMethodEnabled
                showPreselectedStoredPaymentMethod = this@toCheckoutConfiguration.showPreselectedStoredPaymentMethod
                skipListWhenSinglePaymentMethod = this@toCheckoutConfiguration.skipListWhenSinglePaymentMethod
                paymentMethodNames?.forEach { (paymentMethodType, paymentMethodName) ->
                    if (paymentMethodType != null && paymentMethodName != null) {
                        overridePaymentMethodName(paymentMethodType, paymentMethodName)
                    }
                }
            }
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
                    addressConfiguration = configurationDTO.addressMode.mapToAddressConfiguration()
                    isStorePaymentFieldVisible = configurationDTO.showStorePaymentField
                    isHideCvcStoredCard = !configurationDTO.showCvcForStoredCard
                    isHideCvc = !configurationDTO.showCvc
                    kcpAuthVisibility = determineKcpAuthVisibility(configurationDTO.kcpFieldVisibility)
                    socialSecurityNumberVisibility =
                        determineSocialSecurityNumberVisibility(configurationDTO.socialSecurityNumberFieldVisibility)
                    supportedCardBrands = mapToSupportedCardBrands(configurationDTO.supportedCardTypes)
                    isHolderNameRequired = configurationDTO.holderNameRequired
                }
            }

            threeDS2ConfigurationDTO?.let { configurationDTO ->
                adyen3DS2 {
                    threeDSRequestorAppURL = configurationDTO.requestorAppURL
                    configurationDTO.uiCustomization?.let { customizationDTO ->
                        uiCustomization = customizationDTO.toUiCustomization()
                    }
                }
            }

            googlePayConfigurationDTO?.let { configurationDTO ->
                googlePay {
                    googlePayEnvironment = configurationDTO.googlePayEnvironment.mapToWalletConstants()
                    this.countryCode = countryCode
                    merchantAccount = configurationDTO.merchantAccount
                    merchantInfo = configurationDTO.merchantInfoDTO?.mapToMerchantInfo()
                    totalPriceStatus = configurationDTO.totalPriceStatus?.mapToTotalPriceStatus()
                    configurationDTO.allowedCardNetworks?.let { allowedCardNetworks = it.filterNotNull() }
                    configurationDTO.allowedAuthMethods?.let { allowedAuthMethods = it.filterNotNull() }
                    configurationDTO.allowPrepaidCards?.let { isAllowPrepaidCards = it }
                    configurationDTO.allowCreditCards?.let { isAllowCreditCards = it }
                    configurationDTO.assuranceDetailsRequired?.let { isAssuranceDetailsRequired = it }
                    configurationDTO.emailRequired?.let { isEmailRequired = it }
                    configurationDTO.existingPaymentMethodRequired?.let { isExistingPaymentMethodRequired = it }
                    configurationDTO.shippingAddressRequired?.let { isShippingAddressRequired = it }
                    shippingAddressParameters =
                        configurationDTO.shippingAddressParametersDTO?.mapToShippingAddressParameters()
                    configurationDTO.billingAddressRequired?.let { isBillingAddressRequired = it }
                    billingAddressParameters =
                        configurationDTO.billingAddressParametersDTO?.mapToBillingAddressParameters()
                }
            }

            cashAppPayConfigurationDTO?.let { configurationDTO ->
                cashAppPay {
                    cashAppPayEnvironment = configurationDTO.cashAppPayEnvironment.mapToCashAppPayEnvironment()
                    returnUrl = configurationDTO.returnUrl
                }
            }

            twintConfigurationDTO?.let { configurationDTO ->
                twint {
                    showStorePaymentField = configurationDTO.showStorePaymentField
                }
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
            Environment.EUROPE -> SDKEnvironment.EUROPE
            Environment.UNITED_STATES -> SDKEnvironment.UNITED_STATES
            Environment.AUSTRALIA -> SDKEnvironment.AUSTRALIA
            Environment.INDIA -> SDKEnvironment.INDIA
            Environment.APSE -> SDKEnvironment.APSE
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

    private fun mapToSupportedCardBrands(cardTypes: List<String?>?): List<CardBrand> =
        cardTypes.orEmpty().filterNotNull().map { CardBrand(it.lowercase()) }

    private fun AmountDTO.mapToAmount(): Amount = Amount(this.currency, this.value)

    private fun Amount.mapToDTOAmount(): AmountDTO =
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
                dto.textColor?.let {
                    setTextColor(it)
                    // TODO: remove when 3DS SDK maps screen textColor to selection text automatically
                    // Why is it not applied?
                    selectionItemCustomization =
                        SelectionItemCustomization().apply {
                            textColor = it
                            selectionIndicatorTintColor = it
                        }
                }
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
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.OPEN_OOB_APP)
            }

            this@toUiCustomization.secondaryButtonCustomization?.let { dto ->
                val buttonCustomization = dto.toButtonCustomization()
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.CANCEL)
                setButtonCustomization(buttonCustomization, UiCustomization.ButtonType.RESEND)
            }
        }

    private fun ThreeDS2ToolbarCustomizationDTO.toToolbarCustomization(): ToolbarCustomization =
        ToolbarCustomization().apply {
            this@toToolbarCustomization.backgroundColor?.let { backgroundColor = it }
            this@toToolbarCustomization.headerText?.let { headerText = it }
            this@toToolbarCustomization.buttonText?.let { buttonText = it }
            this@toToolbarCustomization.textColor?.let { textColor = it }
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
}
