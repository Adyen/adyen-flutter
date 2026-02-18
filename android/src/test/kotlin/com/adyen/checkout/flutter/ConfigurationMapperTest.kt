package com.adyen.checkout.flutter

import com.adyen.checkout.adyen3ds2.Adyen3DS2Configuration
import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.cashapppay.CashAppPayConfiguration
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.cse.EncryptedCard
import com.adyen.checkout.dropin.DropInConfiguration
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
import com.adyen.checkout.flutter.generated.Environment
import com.adyen.checkout.flutter.generated.FieldVisibility
import com.adyen.checkout.flutter.generated.GooglePayConfigurationDTO
import com.adyen.checkout.flutter.generated.GooglePayEnvironment
import com.adyen.checkout.flutter.generated.InstantPaymentConfigurationDTO
import com.adyen.checkout.flutter.generated.MerchantInfoDTO
import com.adyen.checkout.flutter.generated.ShippingAddressParametersDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ConfigurationDTO
import com.adyen.checkout.flutter.generated.TotalPriceStatus
import com.adyen.checkout.flutter.generated.TwintConfigurationDTO
import com.adyen.checkout.flutter.generated.InstantPaymentType
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEncryptedCardDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEnvironment
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToOrderResponseModel
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.checkout.googlepay.GooglePayConfiguration
import com.adyen.checkout.twint.TwintConfiguration
import com.google.android.gms.wallet.WalletConstants
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import kotlin.jvm.java
import kotlin.test.assertIs
import com.adyen.checkout.cashapppay.CashAppPayEnvironment as SDKCashAppPayEnvironment
import com.adyen.checkout.core.Environment as SDKEnvironment


class ConfigurationMapperTest {
    private val TEST_CLIENT_KEY = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    @Nested
    inner class EnvironmentMappingTests {
        @Test
        fun `when environment is TEST, then map to SDK TEST environment`() {
            assertEquals(SDKEnvironment.TEST, Environment.TEST.mapToEnvironment())
        }

        @Test
        fun `when environment is EUROPE, then map to SDK EUROPE environment`() {
            assertEquals(SDKEnvironment.EUROPE, Environment.EUROPE.mapToEnvironment())
        }

        @Test
        fun `when environment is UNITED_STATES, then map to SDK UNITED_STATES environment`() {
            assertEquals(SDKEnvironment.UNITED_STATES, Environment.UNITED_STATES.mapToEnvironment())
        }

        @Test
        fun `when environment is AUSTRALIA, then map to SDK AUSTRALIA environment`() {
            assertEquals(SDKEnvironment.AUSTRALIA, Environment.AUSTRALIA.mapToEnvironment())
        }

        @Test
        fun `when environment is INDIA, then map to SDK INDIA environment`() {
            assertEquals(SDKEnvironment.INDIA, Environment.INDIA.mapToEnvironment())
        }

        @Test
        fun `when environment is APSE, then map to SDK APSE environment`() {
            assertEquals(SDKEnvironment.APSE, Environment.APSE.mapToEnvironment())
        }
    }

    @Nested
    inner class OrderResponseMappingTests {
        @Test
        fun `when order response has all fields, then map to DTO correctly`() {
            val orderResponse = OrderResponse(
                pspReference = "pspRef123",
                orderData = "orderData456",
                amount = Amount("EUR", 1000),
                remainingAmount = Amount("EUR", 500),
            )

            val dto = orderResponse.mapToOrderResponseModel()

            assertEquals("pspRef123", dto.pspReference)
            assertEquals("orderData456", dto.orderData)
            assertEquals("EUR", dto.amount?.currency)
            assertEquals(1000, dto.amount?.value)
            assertEquals("EUR", dto.remainingAmount?.currency)
            assertEquals(500, dto.remainingAmount?.value)
        }

        @Test
        fun `when order response has null amounts, then map to DTO with null amounts`() {
            val orderResponse = OrderResponse(
                pspReference = "pspRef123",
                orderData = "orderData456",
                amount = null,
                remainingAmount = null,
            )

            val dto = orderResponse.mapToOrderResponseModel()

            assertEquals("pspRef123", dto.pspReference)
            assertEquals("orderData456", dto.orderData)
            assertNull(dto.amount)
            assertNull(dto.remainingAmount)
        }
    }

    @Nested
    inner class DropInConfigurationTests {
        @Test
        fun `when minimal dropin configuration is provided, then map correctly`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "NL",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "0.0.1"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.TEST, checkoutConfiguration.environment)
            assertEquals(TEST_CLIENT_KEY, checkoutConfiguration.clientKey)
        }

        @Test
        fun `when dropin configuration DTO is provided, then map it to native dropin configuration model`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                shopperLocale = "en-US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                showPreselectedStoredPaymentMethod = false,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = true,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
            val dropInConfiguration = checkoutConfiguration.getConfiguration<DropInConfiguration>("DROP_IN_CONFIG_KEY")

            assertEquals(SDKEnvironment.TEST, checkoutConfiguration.environment)
            assertEquals(TEST_CLIENT_KEY, checkoutConfiguration.clientKey)
            assertEquals("en-US", checkoutConfiguration.shopperLocale?.toLanguageTag())
            assertEquals("USD", checkoutConfiguration.amount?.currency)
            assertEquals(1824, checkoutConfiguration.amount?.value)
            assertEquals(false, dropInConfiguration?.showPreselectedStoredPaymentMethod)
            assertEquals(false, dropInConfiguration?.skipListWhenSinglePaymentMethod)
            assertEquals(false, dropInConfiguration?.isRemovingStoredPaymentMethodsEnabled)
        }

        @Test
        fun `when dropin configuration has payment method names, then override names correctly`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "0.0.1"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = true,
                isRemoveStoredPaymentMethodEnabled = true,
                isPartialPaymentSupported = false,
                paymentMethodNames = mapOf("scheme" to "Credit Card", "ideal" to "iDEAL Payment"),
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
            val dropInConfiguration = checkoutConfiguration.getConfiguration<DropInConfiguration>("DROP_IN_CONFIG_KEY")

            assertEquals(true, dropInConfiguration?.showPreselectedStoredPaymentMethod)
            assertEquals(true, dropInConfiguration?.skipListWhenSinglePaymentMethod)
            assertEquals(true, dropInConfiguration?.isRemovingStoredPaymentMethodsEnabled)
        }

        @Test
        fun `when dropin configuration has null optional fields, then map correctly`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "NL",
                shopperLocale = null,
                amount = null,
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "0.0.1"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.TEST, checkoutConfiguration.environment)
            assertNull(checkoutConfiguration.shopperLocale)
            assertNull(checkoutConfiguration.amount)
        }
    }

    @Nested
    inner class CardConfigurationTests {
        @Test
        fun `when card configuration has address mode FULL, then map to FullAddress`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = true,
                addressMode = AddressMode.FULL,
                showStorePaymentField = true,
                showCvcForStoredCard = true,
                showCvc = true,
                kcpFieldVisibility = FieldVisibility.HIDE,
                socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                supportedCardTypes = emptyList()
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                shopperLocale = "en-US",
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertIs<AddressConfiguration.FullAddress>(cardConfiguration?.addressConfiguration)
        }

        @Test
        fun `when card configuration has address mode POSTAL_CODE, then map to PostalCode`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = false,
                addressMode = AddressMode.POSTAL_CODE,
                showStorePaymentField = true,
                showCvcForStoredCard = true,
                showCvc = true,
                kcpFieldVisibility = FieldVisibility.HIDE,
                socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                supportedCardTypes = emptyList()
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertIs<AddressConfiguration.PostalCode>(cardConfiguration?.addressConfiguration)
        }

        @Test
        fun `when card configuration has address mode NONE, then map to None`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = false,
                addressMode = AddressMode.NONE,
                showStorePaymentField = true,
                showCvcForStoredCard = true,
                showCvc = true,
                kcpFieldVisibility = FieldVisibility.HIDE,
                socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                supportedCardTypes = emptyList()
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertIs<AddressConfiguration.None>(cardConfiguration?.addressConfiguration)
        }

        @Test
        fun `when card configuration has KCP visibility SHOW, then map correctly`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = false,
                addressMode = AddressMode.NONE,
                showStorePaymentField = true,
                showCvcForStoredCard = true,
                showCvc = true,
                kcpFieldVisibility = FieldVisibility.SHOW,
                socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                supportedCardTypes = emptyList()
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertEquals(KCPAuthVisibility.SHOW, cardConfiguration?.kcpAuthVisibility)
        }

        @Test
        fun `when card configuration has SSN visibility SHOW, then map correctly`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = false,
                addressMode = AddressMode.NONE,
                showStorePaymentField = true,
                showCvcForStoredCard = true,
                showCvc = true,
                kcpFieldVisibility = FieldVisibility.HIDE,
                socialSecurityNumberFieldVisibility = FieldVisibility.SHOW,
                supportedCardTypes = emptyList()
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertEquals(SocialSecurityNumberVisibility.SHOW, cardConfiguration?.socialSecurityNumberVisibility)
        }

        @Test
        fun `when card configuration has supported card types, then map correctly`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = true,
                addressMode = AddressMode.NONE,
                showStorePaymentField = false,
                showCvcForStoredCard = false,
                showCvc = false,
                kcpFieldVisibility = FieldVisibility.HIDE,
                socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                supportedCardTypes = listOf("visa", "mc", "amex")
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertEquals(3, cardConfiguration?.supportedCardBrands?.size)
            assertEquals(true, cardConfiguration?.isHolderNameRequired)
            assertEquals(false, cardConfiguration?.isStorePaymentFieldVisible)
            assertEquals(true, cardConfiguration?.isHideCvcStoredCard)
            assertEquals(true, cardConfiguration?.isHideCvc)
        }

        @Test
        fun `when card configuration has null card types, then map to empty list`() {
            val cardConfigurationDTO = CardConfigurationDTO(
                holderNameRequired = false,
                addressMode = AddressMode.NONE,
                showStorePaymentField = true,
                showCvcForStoredCard = true,
                showCvc = true,
                kcpFieldVisibility = FieldVisibility.HIDE,
                socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                supportedCardTypes = emptyList()
            )
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = cardConfigurationDTO,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val cardConfiguration = checkoutConfiguration.getConfiguration<CardConfiguration>(PaymentMethodTypes.SCHEME)

            assertEquals(0, cardConfiguration?.supportedCardBrands?.size)
        }
    }

    @Nested
    inner class ActionComponentConfigurationTests {
        @Test
        fun `when action component configuration is provided, then map correctly`() {
            val actionConfigurationDTO = ActionComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                shopperLocale = "nl-NL",
                amount = AmountDTO("EUR", 5000),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
            )

            val checkoutConfiguration = actionConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.TEST, checkoutConfiguration.environment)
            assertEquals(TEST_CLIENT_KEY, checkoutConfiguration.clientKey)
            assertEquals("nl-NL", checkoutConfiguration.shopperLocale?.toLanguageTag())
            assertEquals("EUR", checkoutConfiguration.amount?.currency)
            assertEquals(5000, checkoutConfiguration.amount?.value)
        }

        @Test
        fun `when action component configuration has null optional fields, then map correctly`() {
            val actionConfigurationDTO = ActionComponentConfigurationDTO(
                environment = Environment.UNITED_STATES,
                clientKey = TEST_CLIENT_KEY,
                shopperLocale = null,
                amount = null,
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "1.0.0"),
            )

            val checkoutConfiguration = actionConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.UNITED_STATES, checkoutConfiguration.environment)
            assertNull(checkoutConfiguration.shopperLocale)
            assertNull(checkoutConfiguration.amount)
        }
    }

    @Nested
    inner class ThreeDS2ConfigurationTests {
        @Test
        fun `when 3DS2 configuration is provided, then map requestorAppURL correctly`() {
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = CardConfigurationDTO(
                    holderNameRequired = false,
                    addressMode = AddressMode.NONE,
                    showStorePaymentField = true,
                    showCvcForStoredCard = true,
                    showCvc = true,
                    kcpFieldVisibility = FieldVisibility.HIDE,
                    socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                    supportedCardTypes = emptyList()
                ),
                threeDS2ConfigurationDTO = ThreeDS2ConfigurationDTO(
                    requestorAppURL = "https://example.com/3ds2"
                ),
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val threeDS2Configuration = checkoutConfiguration.getActionConfiguration(Adyen3DS2Configuration::class.java)

            assertEquals("https://example.com/3ds2", threeDS2Configuration?.threeDSRequestorAppURL)
        }

        @Test
        fun `when 3DS2 configuration is null, then no 3DS2 config is added`() {
            val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1824),
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
                cardConfiguration = CardConfigurationDTO(
                    holderNameRequired = false,
                    addressMode = AddressMode.NONE,
                    showStorePaymentField = true,
                    showCvcForStoredCard = true,
                    showCvc = true,
                    kcpFieldVisibility = FieldVisibility.HIDE,
                    socialSecurityNumberFieldVisibility = FieldVisibility.HIDE,
                    supportedCardTypes = emptyList()
                ),
                threeDS2ConfigurationDTO = null,
            )

            val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
            val threeDS2Configuration = checkoutConfiguration.getConfiguration<Adyen3DS2Configuration>("threeDS2")

            assertNull(threeDS2Configuration)
        }
    }

    @Nested
    inner class InstantPaymentConfigurationTests {
        @Test
        fun `when instant payment configuration with Google Pay is provided, then map correctly`() {
            val googlePayConfigurationDTO = GooglePayConfigurationDTO(
                googlePayEnvironment = GooglePayEnvironment.TEST,
                merchantAccount = "TestMerchant",
                merchantInfoDTO = MerchantInfoDTO("Test Store", "merchant123"),
                totalPriceStatus = TotalPriceStatus.FINAL_PRICE,
                allowedCardNetworks = listOf("VISA", "MASTERCARD"),
                allowedAuthMethods = listOf("PAN_ONLY", "CRYPTOGRAM_3DS"),
                allowPrepaidCards = true,
                allowCreditCards = true,
                assuranceDetailsRequired = false,
                emailRequired = true,
                existingPaymentMethodRequired = false,
                shippingAddressRequired = true,
                shippingAddressParametersDTO = ShippingAddressParametersDTO(
                    allowedCountryCodes = listOf("US", "CA"),
                    isPhoneNumberRequired = true
                ),
                billingAddressRequired = true,
                billingAddressParametersDTO = BillingAddressParametersDTO(
                    format = "FULL",
                    isPhoneNumberRequired = false
                ),
            )
            val instantPaymentConfigurationDTO = InstantPaymentConfigurationDTO(
                instantPaymentType = InstantPaymentType.GOOGLE_PAY,
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 2500),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                googlePayConfigurationDTO = googlePayConfigurationDTO,
            )

            val checkoutConfiguration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            val googlePayConfiguration =
                checkoutConfiguration.getConfiguration<GooglePayConfiguration>(PaymentMethodTypes.GOOGLE_PAY)

            assertEquals(WalletConstants.ENVIRONMENT_TEST, googlePayConfiguration?.googlePayEnvironment)
            assertEquals("TestMerchant", googlePayConfiguration?.merchantAccount)
            assertEquals("Test Store", googlePayConfiguration?.merchantInfo?.merchantName)
            assertEquals("merchant123", googlePayConfiguration?.merchantInfo?.merchantId)
            assertEquals(true, googlePayConfiguration?.isAllowPrepaidCards)
            assertEquals(true, googlePayConfiguration?.isAllowCreditCards)
            assertEquals(true, googlePayConfiguration?.isEmailRequired)
            assertEquals(true, googlePayConfiguration?.isShippingAddressRequired)
            assertEquals(true, googlePayConfiguration?.isBillingAddressRequired)
        }

        @Test
        fun `when Google Pay has different boolean settings, then map correctly`() {
            val googlePayConfigurationDTO = GooglePayConfigurationDTO(
                googlePayEnvironment = GooglePayEnvironment.TEST,
                merchantAccount = "TestMerchant",
                totalPriceStatus = TotalPriceStatus.ESTIMATED,
                allowPrepaidCards = false,
                allowCreditCards = false,
                assuranceDetailsRequired = true,
                emailRequired = false,
                existingPaymentMethodRequired = true,
                shippingAddressRequired = false,
                billingAddressRequired = false,
            )
            val instantPaymentConfigurationDTO = InstantPaymentConfigurationDTO(
                instantPaymentType = InstantPaymentType.GOOGLE_PAY,
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "NL",
                amount = AmountDTO("EUR", 5000),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                googlePayConfigurationDTO = googlePayConfigurationDTO,
            )

            val checkoutConfiguration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            val googlePayConfiguration =
                checkoutConfiguration.getConfiguration<GooglePayConfiguration>(PaymentMethodTypes.GOOGLE_PAY)

            assertEquals(WalletConstants.ENVIRONMENT_TEST, googlePayConfiguration?.googlePayEnvironment)
            assertEquals(false, googlePayConfiguration?.isAllowPrepaidCards)
            assertEquals(false, googlePayConfiguration?.isAllowCreditCards)
            assertEquals(true, googlePayConfiguration?.isAssuranceDetailsRequired)
            assertEquals(true, googlePayConfiguration?.isExistingPaymentMethodRequired)
        }

        @Test
        fun `when total price status is NOT_CURRENTLY_KNOWN, then map correctly`() {
            val googlePayConfigurationDTO = GooglePayConfigurationDTO(
                googlePayEnvironment = GooglePayEnvironment.TEST,
                merchantAccount = "TestMerchant",
                totalPriceStatus = TotalPriceStatus.NOT_CURRENTLY_KNOWN,
                allowPrepaidCards = true,
                allowCreditCards = true,
                assuranceDetailsRequired = false,
                emailRequired = false,
                existingPaymentMethodRequired = false,
                shippingAddressRequired = false,
                billingAddressRequired = false,
            )
            val instantPaymentConfigurationDTO = InstantPaymentConfigurationDTO(
                instantPaymentType = InstantPaymentType.GOOGLE_PAY,
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1000),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                googlePayConfigurationDTO = googlePayConfigurationDTO,
            )

            val checkoutConfiguration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            val googlePayConfiguration =
                checkoutConfiguration.getConfiguration<GooglePayConfiguration>(PaymentMethodTypes.GOOGLE_PAY)

            assertEquals("NOT_CURRENTLY_KNOWN", googlePayConfiguration?.totalPriceStatus)
        }

        @Test
        fun `when shipping address parameters has no phone required, then use default constructor`() {
            val googlePayConfigurationDTO = GooglePayConfigurationDTO(
                googlePayEnvironment = GooglePayEnvironment.TEST,
                merchantAccount = "TestMerchant",
                totalPriceStatus = null,
                allowPrepaidCards = true,
                allowCreditCards = true,
                assuranceDetailsRequired = false,
                emailRequired = false,
                existingPaymentMethodRequired = false,
                shippingAddressRequired = true,
                shippingAddressParametersDTO = ShippingAddressParametersDTO(
                    allowedCountryCodes = listOf("US"),
                    isPhoneNumberRequired = null
                ),
                billingAddressRequired = false,
            )
            val instantPaymentConfigurationDTO = InstantPaymentConfigurationDTO(
                instantPaymentType = InstantPaymentType.GOOGLE_PAY,
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1000),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                googlePayConfigurationDTO = googlePayConfigurationDTO,
            )

            val checkoutConfiguration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            val googlePayConfiguration =
                checkoutConfiguration.getConfiguration<GooglePayConfiguration>(PaymentMethodTypes.GOOGLE_PAY)

            assertEquals(listOf("US"), googlePayConfiguration?.shippingAddressParameters?.allowedCountryCodes)
        }

        @Test
        fun `when billing address parameters has no phone required, then use default constructor`() {
            val googlePayConfigurationDTO = GooglePayConfigurationDTO(
                googlePayEnvironment = GooglePayEnvironment.TEST,
                merchantAccount = "TestMerchant",
                totalPriceStatus = null,
                allowPrepaidCards = true,
                allowCreditCards = true,
                assuranceDetailsRequired = false,
                emailRequired = false,
                existingPaymentMethodRequired = false,
                shippingAddressRequired = false,
                billingAddressRequired = true,
                billingAddressParametersDTO = BillingAddressParametersDTO(
                    format = "MIN",
                    isPhoneNumberRequired = null
                ),
            )
            val instantPaymentConfigurationDTO = InstantPaymentConfigurationDTO(
                instantPaymentType = InstantPaymentType.GOOGLE_PAY,
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1000),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                googlePayConfigurationDTO = googlePayConfigurationDTO,
            )

            val checkoutConfiguration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            val googlePayConfiguration =
                checkoutConfiguration.getConfiguration<GooglePayConfiguration>(PaymentMethodTypes.GOOGLE_PAY)

            assertEquals("MIN", googlePayConfiguration?.billingAddressParameters?.format)
        }

        @Test
        fun `when Google Pay nullable boolean properties are null, then configuration values are null`() {
            val googlePayConfigurationDTO = GooglePayConfigurationDTO(
                googlePayEnvironment = GooglePayEnvironment.TEST,
                merchantAccount = "TestMerchant",
                totalPriceStatus = null,
                allowPrepaidCards = null,
                allowCreditCards = null,
                assuranceDetailsRequired = null,
                emailRequired = null,
                existingPaymentMethodRequired = null,
                shippingAddressRequired = null,
                billingAddressRequired = null,
            )
            val instantPaymentConfigurationDTO = InstantPaymentConfigurationDTO(
                instantPaymentType = InstantPaymentType.GOOGLE_PAY,
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                amount = AmountDTO("USD", 1000),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                googlePayConfigurationDTO = googlePayConfigurationDTO,
            )

            val checkoutConfiguration = instantPaymentConfigurationDTO.toCheckoutConfiguration()
            val googlePayConfiguration =
                checkoutConfiguration.getConfiguration<GooglePayConfiguration>(PaymentMethodTypes.GOOGLE_PAY)

            assertEquals(null, googlePayConfiguration?.isAllowPrepaidCards)
            assertNull(googlePayConfiguration?.isAllowCreditCards)
            assertEquals(null, googlePayConfiguration?.isAssuranceDetailsRequired)
            assertEquals(null, googlePayConfiguration?.isEmailRequired)
            assertEquals(null, googlePayConfiguration?.isExistingPaymentMethodRequired)
            assertEquals(null, googlePayConfiguration?.isShippingAddressRequired)
            assertEquals(null, googlePayConfiguration?.isBillingAddressRequired)
        }
    }

    @Nested
    inner class CashAppPayConfigurationTests {
        @Test
        fun `when Cash App Pay configuration with SANDBOX environment is provided, then map correctly`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
                cashAppPayConfigurationDTO = CashAppPayConfigurationDTO(
                    cashAppPayEnvironment = CashAppPayEnvironment.SANDBOX,
                    returnUrl = "myapp://cashapp/callback"
                ),
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
            val cashAppPayConfiguration =
                checkoutConfiguration.getConfiguration<CashAppPayConfiguration>(PaymentMethodTypes.CASH_APP_PAY)

            assertEquals(SDKCashAppPayEnvironment.SANDBOX, cashAppPayConfiguration?.cashAppPayEnvironment)
            assertEquals("myapp://cashapp/callback", cashAppPayConfiguration?.returnUrl)
        }
    }

    @Nested
    inner class TwintConfigurationTests {
        @Test
        fun `when Twint configuration is provided, then map showStorePaymentField correctly`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "CH",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
                twintConfigurationDTO = TwintConfigurationDTO(
                    iosCallbackAppScheme = "myapp",
                    showStorePaymentField = true
                ),
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
            val twintConfiguration =
                checkoutConfiguration.getConfiguration<TwintConfiguration>(PaymentMethodTypes.TWINT)

            assertEquals(true, twintConfiguration?.showStorePaymentField)
        }

        @Test
        fun `when Twint configuration has showStorePaymentField false, then map correctly`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "CH",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
                twintConfigurationDTO = TwintConfigurationDTO(
                    iosCallbackAppScheme = "myapp",
                    showStorePaymentField = false
                ),
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()
            val twintConfiguration =
                checkoutConfiguration.getConfiguration<TwintConfiguration>(PaymentMethodTypes.TWINT)

            assertEquals(false, twintConfiguration?.showStorePaymentField)
        }
    }

    @Nested
    inner class EncryptedCardMappingTests {
        @Test
        fun `when encrypted card is provided, then map to DTO correctly`() {
            val encryptedCard = EncryptedCard(
                encryptedCardNumber = "encNumber123",
                encryptedExpiryMonth = "encMonth456",
                encryptedExpiryYear = "encYear789",
                encryptedSecurityCode = "encCvc000"
            )

            val dto = encryptedCard.mapToEncryptedCardDTO()

            assertEquals("encNumber123", dto.encryptedCardNumber)
            assertEquals("encMonth456", dto.encryptedExpiryMonth)
            assertEquals("encYear789", dto.encryptedExpiryYear)
            assertEquals("encCvc000", dto.encryptedSecurityCode)
        }
    }

    @Nested
    inner class UnencryptedCardMappingTests {
        @Test
        fun `when unencrypted card DTO has all fields, then map correctly`() {
            val unencryptedCardDTO = UnencryptedCardDTO(
                cardNumber = "4111111111111111",
                expiryMonth = "03",
                expiryYear = "2030",
                cvc = "737"
            )

            val unencryptedCard = unencryptedCardDTO.fromDTO()

            assertEquals("4111111111111111", unencryptedCard.number)
            assertEquals("03", unencryptedCard.expiryMonth)
            assertEquals("2030", unencryptedCard.expiryYear)
            assertEquals("737", unencryptedCard.cvc)
        }

        @Test
        fun `when unencrypted card DTO has null card number, then build without number`() {
            val unencryptedCardDTO = UnencryptedCardDTO(
                cardNumber = null,
                expiryMonth = "03",
                expiryYear = "2030",
                cvc = "737"
            )

            val unencryptedCard = unencryptedCardDTO.fromDTO()

            assertNull(unencryptedCard.number)
            assertEquals("03", unencryptedCard.expiryMonth)
            assertEquals("2030", unencryptedCard.expiryYear)
        }

        @Test
        fun `when unencrypted card DTO has null expiry month, then build without expiry date`() {
            val unencryptedCardDTO = UnencryptedCardDTO(
                cardNumber = "4111111111111111",
                expiryMonth = null,
                expiryYear = "2030",
                cvc = "737"
            )

            val unencryptedCard = unencryptedCardDTO.fromDTO()

            assertEquals("4111111111111111", unencryptedCard.number)
            assertNull(unencryptedCard.expiryMonth)
            assertNull(unencryptedCard.expiryYear)
        }

        @Test
        fun `when unencrypted card DTO has null expiry year, then build without expiry date`() {
            val unencryptedCardDTO = UnencryptedCardDTO(
                cardNumber = "4111111111111111",
                expiryMonth = "03",
                expiryYear = null,
                cvc = "737"
            )

            val unencryptedCard = unencryptedCardDTO.fromDTO()

            assertNull(unencryptedCard.expiryMonth)
            assertNull(unencryptedCard.expiryYear)
        }

        @Test
        fun `when unencrypted card DTO has null cvc, then build without cvc`() {
            val unencryptedCardDTO = UnencryptedCardDTO(
                cardNumber = "4111111111111111",
                expiryMonth = "03",
                expiryYear = "2030",
                cvc = null
            )

            val unencryptedCard = unencryptedCardDTO.fromDTO()

            assertEquals("4111111111111111", unencryptedCard.number)
            assertNull(unencryptedCard.cvc)
        }

        @Test
        fun `when unencrypted card DTO has all null fields, then build empty card`() {
            val unencryptedCardDTO = UnencryptedCardDTO(
                cardNumber = null,
                expiryMonth = null,
                expiryYear = null,
                cvc = null
            )

            val unencryptedCard = unencryptedCardDTO.fromDTO()

            assertNull(unencryptedCard.number)
            assertNull(unencryptedCard.expiryMonth)
            assertNull(unencryptedCard.expiryYear)
            assertNull(unencryptedCard.cvc)
        }
    }

    @Nested
    inner class AnalyticsConfigurationTests {
        @Test
        fun `when analytics is enabled, then analytics level is ALL`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                analyticsOptionsDTO = AnalyticsOptionsDTO(enabled = true, version = "1.0.0"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()

            assertEquals(
                com.adyen.checkout.components.core.AnalyticsLevel.ALL,
                checkoutConfiguration.analyticsConfiguration?.level
            )
        }

        @Test
        fun `when analytics is disabled, then analytics level is NONE`() {
            val dropInConfigurationDTO = DropInConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "US",
                analyticsOptionsDTO = AnalyticsOptionsDTO(enabled = false, version = "1.0.0"),
                showPreselectedStoredPaymentMethod = true,
                skipListWhenSinglePaymentMethod = false,
                isRemoveStoredPaymentMethodEnabled = false,
                isPartialPaymentSupported = false,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()

            assertEquals(
                com.adyen.checkout.components.core.AnalyticsLevel.NONE,
                checkoutConfiguration.analyticsConfiguration?.level
            )
        }
    }
}
