package com.adyen.checkout.flutter

import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.card.FieldVisibility as SdkFieldVisibility
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.OrderResponse
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.cse.EncryptedCard
import com.adyen.checkout.flutter.generated.ActionComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.AddressMode
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsOptionsDTO
import com.adyen.checkout.flutter.generated.BillingAddressParametersDTO
import com.adyen.checkout.flutter.generated.BlikComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardBasedInstallmentOptionsDTO
import com.adyen.checkout.flutter.generated.CardConfigurationDTO
import com.adyen.checkout.flutter.generated.CashAppPayConfigurationDTO
import com.adyen.checkout.flutter.generated.CashAppPayEnvironment
import com.adyen.checkout.flutter.generated.DefaultInstallmentOptionsDTO
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.Environment
import com.adyen.checkout.flutter.generated.FieldVisibility
import com.adyen.checkout.flutter.generated.GooglePayConfigurationDTO
import com.adyen.checkout.flutter.generated.GooglePayEnvironment
import com.adyen.checkout.flutter.generated.InstallmentConfigurationDTO
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
import com.google.android.gms.wallet.WalletConstants
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import kotlin.jvm.java
import kotlin.test.assertIs
import com.adyen.checkout.cashapppay.CashAppPayEnvironment as SDKCashAppPayEnvironment
import com.adyen.checkout.core.common.Environment as SDKEnvironment


class ConfigurationMapperTest {
    private val TEST_CLIENT_KEY = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    private fun hasInternalThreeDS2Configuration(checkoutConfiguration: com.adyen.checkout.core.components.CheckoutConfiguration): Boolean {
        return try {
            val getConfigurationMethod = checkoutConfiguration.javaClass.getDeclaredMethod("getActionConfiguration", Class::class.java)
            val threeDS2ConfigClass = Class.forName("com.adyen.checkout.threeds2.ThreeDS2Configuration")
            getConfigurationMethod.invoke(checkoutConfiguration, threeDS2ConfigClass) != null
        } catch (e: Exception) {
            false
        }
    }

    private fun getInternalThreeDSRequestorAppURL(checkoutConfiguration: com.adyen.checkout.core.components.CheckoutConfiguration): String? {
        return try {
            val getConfigurationMethod = checkoutConfiguration.javaClass.getDeclaredMethod("getActionConfiguration", Class::class.java)
            val threeDS2ConfigClass = Class.forName("com.adyen.checkout.threeds2.ThreeDS2Configuration")
            val config = getConfigurationMethod.invoke(checkoutConfiguration, threeDS2ConfigClass) ?: return null
            val getThreeDSRequestorAppURLMethod = config.javaClass.getDeclaredMethod("getThreeDSRequestorAppURL")
            getThreeDSRequestorAppURLMethod.isAccessible = true
            getThreeDSRequestorAppURLMethod.invoke(config) as String?
        } catch (e: Exception) {
            null
        }
    }

    @Nested
    inner class EnvironmentMappingTests {
        @Test
        fun `when environment is TEST, then map to SDK TEST environment`() {
            assertEquals(SDKEnvironment.TEST, Environment.TEST.mapToEnvironment())
        }

        @Test
        fun `when environment is LIVE_EUROPE, then map to SDK LIVE_EUROPE environment`() {
            assertEquals(SDKEnvironment.LIVE_EUROPE, Environment.LIVE_EUROPE.mapToEnvironment())
        }

        @Test
        fun `when environment is LIVE_UNITED_STATES, then map to SDK LIVE_UNITED_STATES environment`() {
            assertEquals(SDKEnvironment.LIVE_UNITED_STATES, Environment.LIVE_UNITED_STATES.mapToEnvironment())
        }

        @Test
        fun `when environment is LIVE_AUSTRALIA, then map to SDK LIVE_AUSTRALIA environment`() {
            assertEquals(SDKEnvironment.LIVE_AUSTRALIA, Environment.LIVE_AUSTRALIA.mapToEnvironment())
        }

        @Test
        fun `when environment is LIVE_APSE, then map to SDK LIVE_APSE environment`() {
            assertEquals(SDKEnvironment.LIVE_APSE, Environment.LIVE_APSE.mapToEnvironment())
        }

        @Test
        fun `when environment is LIVE_INDIA, then map to SDK LIVE_INDIA environment`() {
            assertEquals(SDKEnvironment.LIVE_INDIA, Environment.LIVE_INDIA.mapToEnvironment())
        }

        @Test
        fun `when environment is LIVE_NEA, then map to SDK LIVE_NEA environment`() {
            assertEquals(SDKEnvironment.LIVE_NEA, Environment.LIVE_NEA.mapToEnvironment())
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
    inner class CardConfigurationTests {
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

            assertEquals(SdkFieldVisibility.SHOW, cardConfiguration?.koreanAuthenticationVisibility)
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

            assertEquals(SdkFieldVisibility.SHOW, cardConfiguration?.socialSecurityNumberVisibility)
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
            assertEquals(true, cardConfiguration?.showCardholderName)
            assertEquals(false, cardConfiguration?.showStorePaymentMethod)
            assertEquals(false, cardConfiguration?.showSecurityCodeForStoredCard)
            assertEquals(false, cardConfiguration?.showSecurityCode)
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
                threeDS2ConfigurationDTO = null,
            )

            val checkoutConfiguration = actionConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.TEST, checkoutConfiguration.environment)
            assertEquals(TEST_CLIENT_KEY, checkoutConfiguration.clientKey)
            assertEquals("nl-NL", checkoutConfiguration.shopperLocale?.toLanguageTag())
            assertEquals("EUR", checkoutConfiguration.amount?.currency)
            assertEquals(5000, checkoutConfiguration.amount?.value)
            assertFalse(hasInternalThreeDS2Configuration(checkoutConfiguration))
        }

        @Test
        fun `when action component configuration has null optional fields, then map correctly`() {
            val actionConfigurationDTO = ActionComponentConfigurationDTO(
                environment = Environment.LIVE_UNITED_STATES,
                clientKey = TEST_CLIENT_KEY,
                shopperLocale = null,
                amount = null,
                analyticsOptionsDTO = AnalyticsOptionsDTO(false, "1.0.0"),
                threeDS2ConfigurationDTO = null,
            )

            val checkoutConfiguration = actionConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.LIVE_UNITED_STATES, checkoutConfiguration.environment)
            assertNull(checkoutConfiguration.shopperLocale)
            assertNull(checkoutConfiguration.amount)
            assertFalse(hasInternalThreeDS2Configuration(checkoutConfiguration))
        }

        @Test
        fun `when action component configuration has 3DS2 configuration, then map correctly`() {
            val actionConfigurationDTO = ActionComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                shopperLocale = null,
                amount = null,
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
                threeDS2ConfigurationDTO = ThreeDS2ConfigurationDTO(
                    requestorAppURL = "https://example.com/action-3ds2"
                ),
            )

            val checkoutConfiguration = actionConfigurationDTO.toCheckoutConfiguration()
            assertEquals("https://example.com/action-3ds2", getInternalThreeDSRequestorAppURL(checkoutConfiguration))
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
            assertEquals("https://example.com/3ds2", getInternalThreeDSRequestorAppURL(checkoutConfiguration))
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
            assertFalse(hasInternalThreeDS2Configuration(checkoutConfiguration))
        }
    }

    /*
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
    */

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
    inner class BlikConfigurationTests {
        @Test
        fun `when blik configuration is provided, then map environment and clientKey correctly`() {
            val blikConfigurationDTO = BlikComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "PL",
                amount = AmountDTO("PLN", 1000),
                shopperLocale = "pl-PL",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
            )

            val checkoutConfiguration = blikConfigurationDTO.toCheckoutConfiguration()

            assertEquals(SDKEnvironment.TEST, checkoutConfiguration.environment)
            assertEquals(TEST_CLIENT_KEY, checkoutConfiguration.clientKey)
        }

        @Test
        fun `when blik configuration has shopperLocale, then map correctly`() {
            val blikConfigurationDTO = BlikComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "PL",
                amount = AmountDTO("PLN", 1000),
                shopperLocale = "pl-PL",
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
            )

            val checkoutConfiguration = blikConfigurationDTO.toCheckoutConfiguration()

            assertEquals("pl-PL", checkoutConfiguration.shopperLocale?.toLanguageTag())
        }

        @Test
        fun `when blik configuration has amount, then map currency and value correctly`() {
            val blikConfigurationDTO = BlikComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "PL",
                amount = AmountDTO("PLN", 2500),
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
            )

            val checkoutConfiguration = blikConfigurationDTO.toCheckoutConfiguration()

            assertEquals("PLN", checkoutConfiguration.amount?.currency)
            assertEquals(2500, checkoutConfiguration.amount?.value)
        }

        @Test
        fun `when blik configuration has null shopperLocale, then shopperLocale is null`() {
            val blikConfigurationDTO = BlikComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "PL",
                shopperLocale = null,
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
            )

            val checkoutConfiguration = blikConfigurationDTO.toCheckoutConfiguration()

            assertNull(checkoutConfiguration.shopperLocale)
        }

        @Test
        fun `when blik configuration has null amount, then amount is null`() {
            val blikConfigurationDTO = BlikComponentConfigurationDTO(
                environment = Environment.TEST,
                clientKey = TEST_CLIENT_KEY,
                countryCode = "PL",
                amount = null,
                analyticsOptionsDTO = AnalyticsOptionsDTO(true, "1.0.0"),
            )

            val checkoutConfiguration = blikConfigurationDTO.toCheckoutConfiguration()

            assertNull(checkoutConfiguration.amount)
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
                showStoredPaymentMethods = true,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()

            assertEquals(
                com.adyen.checkout.core.components.AnalyticsLevel.ALL,
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
                showStoredPaymentMethods = true,
            )

            val checkoutConfiguration = dropInConfigurationDTO.toCheckoutConfiguration()

            assertEquals(
                com.adyen.checkout.core.components.AnalyticsLevel.NONE,
                checkoutConfiguration.analyticsConfiguration?.level
            )
        }
    }
}
