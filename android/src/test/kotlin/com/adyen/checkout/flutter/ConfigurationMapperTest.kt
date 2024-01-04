package com.adyen.checkout.flutter

import AmountDTO
import AnalyticsOptionsDTO
import DropInConfigurationDTO
import Environment
import android.content.Context
import com.adyen.checkout.components.core.Amount
import com.adyen.checkout.core.internal.util.LogUtil
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToDropInConfiguration
import com.adyen.checkout.flutter.utils.DropInConfigurationBuilderProvider
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.Mockito.any
import org.mockito.Mockito.anyString
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import java.util.Locale


class ConfigurationMapperTest {
    private val TEST_CLIENT_KEY = "1234567890"
    private val TAG = LogUtil.getTag()
    private val shopperLocale = Locale.US
    private val amount = Amount(currency = "EUR", value = 1337)
    private val environment = Environment.TEST

    @Test
    fun testSum() {
        val dropInConfigurationDTO = DropInConfigurationDTO(
            environment = environment,
            clientKey = TEST_CLIENT_KEY,
            countryCode = "US",
            amount = AmountDTO("USD", 1824),
            analyticsOptionsDTO = AnalyticsOptionsDTO(false, "0.0.1"),
            showPreselectedStoredPaymentMethod = false,
            skipListWhenSinglePaymentMethod = false,
            isRemoveStoredPaymentMethodEnabled = false,
        )
        val mockContext: Context = mock(Context::class.java)
        val dropInConfigurationBuilderProvider: DropInConfigurationBuilderProvider =
            mock(DropInConfigurationBuilderProvider::class.java)
        `when`(
            dropInConfigurationBuilderProvider.buildDropInConfiguration(
                context = mockContext,
                shopperLocale = anyString(),
                environment = any(),
                clientKey = TEST_CLIENT_KEY,
            )
        )

        val dropInConfiguration = dropInConfigurationDTO.mapToDropInConfiguration(
            mockContext,
            dropInConfigurationBuilderProvider,
        )

        assertEquals(dropInConfiguration.environment, Environment.TEST)
    }
}
