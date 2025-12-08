package com.adyen.checkout.flutter

import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.CardConfiguration
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.components.core.CheckoutConfiguration
import com.adyen.checkout.components.core.PaymentMethodTypes
import com.adyen.checkout.dropin.DropIn
import com.adyen.checkout.dropin.DropInConfiguration
import com.adyen.checkout.flutter.generated.AddressMode
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsOptionsDTO
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardConfigurationDTO
import com.adyen.checkout.flutter.generated.DropInConfigurationDTO
import com.adyen.checkout.flutter.generated.Environment
import com.adyen.checkout.flutter.generated.FieldVisibility
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import kotlin.test.assertIs


class ConfigurationMapperTest {
    private val TEST_CLIENT_KEY = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

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

        assertEquals(checkoutConfiguration.environment, com.adyen.checkout.core.Environment.TEST)
        assertEquals(checkoutConfiguration.clientKey, TEST_CLIENT_KEY)
        assertEquals(checkoutConfiguration.shopperLocale?.toLanguageTag(), "en-US")
        assertEquals(checkoutConfiguration.amount?.currency, "USD")
        assertEquals(checkoutConfiguration.amount?.value, 1824)
        assertEquals(dropInConfiguration?.showPreselectedStoredPaymentMethod, false)
        assertEquals(dropInConfiguration?.skipListWhenSinglePaymentMethod, false)
        assertEquals(dropInConfiguration?.isRemovingStoredPaymentMethodsEnabled, false)
    }

    @Test
    fun `when card configuration DTO is provided, then map it to native card model`() {
        val cardConfigurationDTO = CardConfigurationDTO(
            true,
            AddressMode.FULL,
            false,
            true,
            true,
            FieldVisibility.HIDE,
            FieldVisibility.HIDE,
            emptyList()
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

        assertEquals(cardConfiguration?.isHolderNameRequired, true)
        assertIs<AddressConfiguration.FullAddress>(cardConfiguration?.addressConfiguration)
        assertEquals(cardConfiguration?.isStorePaymentFieldVisible, false)
        assertEquals(cardConfiguration?.isHideCvcStoredCard, false)
        assertEquals(cardConfiguration?.kcpAuthVisibility, KCPAuthVisibility.HIDE)
        assertEquals(cardConfiguration?.socialSecurityNumberVisibility, SocialSecurityNumberVisibility.HIDE)
        assertEquals(cardConfiguration?.supportedCardBrands?.size, 0)
    }
}
