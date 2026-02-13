package com.adyen.checkout.flutter

import com.adyen.checkout.adyen3ds2.Adyen3DS2Configuration
import com.adyen.checkout.flutter.generated.AddressMode
import com.adyen.checkout.flutter.generated.AmountDTO
import com.adyen.checkout.flutter.generated.AnalyticsOptionsDTO
import com.adyen.checkout.flutter.generated.CardComponentConfigurationDTO
import com.adyen.checkout.flutter.generated.CardConfigurationDTO
import com.adyen.checkout.flutter.generated.Environment
import com.adyen.checkout.flutter.generated.FieldVisibility
import com.adyen.checkout.flutter.generated.ThreeDS2ButtonCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ConfigurationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2InputCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2LabelCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ScreenCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2ToolbarCustomizationDTO
import com.adyen.checkout.flutter.generated.ThreeDS2UICustomizationDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toCheckoutConfiguration
import com.adyen.threeds2.customization.UiCustomization
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ThreeDS2CustomizationMapperTest {
    private val testClientKey = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    @Test
    fun `when 3DS2 UI customization provided, then map to UiCustomization`() {
        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            headingCustomization = ThreeDS2ToolbarCustomizationDTO(
                headerText = "Heading",
                buttonText = "Cancel",
                textFontSize = 18,
            ),
            labelCustomization = ThreeDS2LabelCustomizationDTO(
                textColor = "#111111",
                textFontSize = 12,
                headingTextColor = "#222222",
                headingTextFontSize = 14,
            ),
        )

        val cardComponentConfigurationDTO = CardComponentConfigurationDTO(
            environment = Environment.TEST,
            clientKey = testClientKey,
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
                requestorAppURL = "https://example.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            ),
        )

        val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
        val threeDS2Configuration = checkoutConfiguration.getActionConfiguration(Adyen3DS2Configuration::class.java)
        val uiCustomization = threeDS2Configuration?.uiCustomization as UiCustomization?

        val toolbar = uiCustomization?.toolbarCustomization
        assertEquals("Heading", toolbar?.headerText)
        assertEquals("Cancel", toolbar?.buttonText)
        assertEquals(18, toolbar?.textFontSize)

        val label = uiCustomization?.labelCustomization
        assertEquals("#111111", label?.textColor)
        assertEquals(12, label?.textFontSize)
        assertEquals("#222222", label?.headingTextColor)
        assertEquals(14, label?.headingTextFontSize)
    }
}
