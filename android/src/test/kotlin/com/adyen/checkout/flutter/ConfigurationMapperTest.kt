package com.adyen.checkout.flutter

import AmountDTO
import AnalyticsOptionsDTO
import CardConfigurationDTO
import DropInConfigurationDTO
import Environment
import FieldVisibility
import android.content.Context
import com.adyen.checkout.card.AddressConfiguration
import com.adyen.checkout.card.KCPAuthVisibility
import com.adyen.checkout.card.SocialSecurityNumberVisibility
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.components.core.AnalyticsConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToDropInConfiguration
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeModel
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock
import kotlin.test.assertIs


class ConfigurationMapperTest {
    private val TEST_CLIENT_KEY = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    @Test
    fun `when dropin configuration DTO is provided, then map it to native dropin configuration model`() {
        val mockContext: Context = mock(Context::class.java)
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
        )

        val dropInConfiguration = dropInConfigurationDTO.mapToDropInConfiguration(mockContext)

        assertEquals(dropInConfiguration.environment, com.adyen.checkout.core.Environment.TEST)
        assertEquals(dropInConfiguration.clientKey, TEST_CLIENT_KEY)
        assertEquals(dropInConfiguration.shopperLocale?.toLanguageTag(), "en-US")
        assertEquals(dropInConfiguration.amount?.currency, "USD")
        assertEquals(dropInConfiguration.amount?.value, 1824)
        assertEquals(dropInConfiguration.showPreselectedStoredPaymentMethod, false)
        assertEquals(dropInConfiguration.skipListWhenSinglePaymentMethod, false)
        assertEquals(dropInConfiguration.isRemovingStoredPaymentMethodsEnabled, false)
    }

    @Test
    fun `when card configuration DTO is provided, then map it to native card model`() {
        val mockContext: Context = mock(Context::class.java)
        val mockAnalyticsConfiguration: AnalyticsConfiguration = mock(AnalyticsConfiguration::class.java)
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

        val cardConfiguration = cardConfigurationDTO.toNativeModel(
            mockContext,
            "en-US",
            com.adyen.checkout.core.Environment.TEST,
            TEST_CLIENT_KEY,
            mockAnalyticsConfiguration,
            Amount("USD", 1800)
        )

        assertEquals(cardConfiguration.isHolderNameRequired, true)
        assertIs<AddressConfiguration.FullAddress>(cardConfiguration.addressConfiguration)
        assertEquals(cardConfiguration.isStorePaymentFieldVisible, false)
        assertEquals(cardConfiguration.isHideCvcStoredCard, false)
        assertEquals(cardConfiguration.kcpAuthVisibility, KCPAuthVisibility.HIDE)
        assertEquals(cardConfiguration.socialSecurityNumberVisibility, SocialSecurityNumberVisibility.HIDE)
        assertEquals(cardConfiguration.supportedCardBrands?.size, 0)
    }
}
