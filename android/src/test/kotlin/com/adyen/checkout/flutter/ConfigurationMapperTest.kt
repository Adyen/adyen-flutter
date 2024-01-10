package com.adyen.checkout.flutter

import AmountDTO
import AnalyticsOptionsDTO
import DropInConfigurationDTO
import Environment
import android.content.Context
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToDropInConfiguration
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.Mockito.mock


class ConfigurationMapperTest {
    private val TEST_CLIENT_KEY = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    @Test
    fun `when dropin configuration DTO is provided, then map it to native SDK model`() {
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
        assertEquals(dropInConfiguration.shopperLocale.toLanguageTag(), "en-US")
        assertEquals(dropInConfiguration.amount?.currency, "USD")
        assertEquals(dropInConfiguration.amount?.value, 1824)
        assertEquals(dropInConfiguration.showPreselectedStoredPaymentMethod, false)
        assertEquals(dropInConfiguration.skipListWhenSinglePaymentMethod, false)
        assertEquals(dropInConfiguration.isRemovingStoredPaymentMethodsEnabled, false)
    }
}
