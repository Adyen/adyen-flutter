package com.adyen.checkout.flutter

import android.graphics.Color
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
import com.adyen.threeds2.customization.ButtonCustomization
import com.adyen.threeds2.customization.ScreenCustomization
import com.adyen.threeds2.customization.TextBoxCustomization
import com.adyen.threeds2.customization.UiCustomization
import io.mockk.every
import io.mockk.mockkStatic
import io.mockk.unmockkAll
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ThreeDS2CustomizationMapperTest {
    private val testClientKey = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    @AfterEach
    fun tearDown() {
        unmockkAll()
    }

    private fun createBaseCardComponentConfiguration(
        threeDS2ConfigurationDTO: ThreeDS2ConfigurationDTO
    ): CardComponentConfigurationDTO {
        return CardComponentConfigurationDTO(
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
            threeDS2ConfigurationDTO = threeDS2ConfigurationDTO,
        )
    }

    @Test
    fun `when 3DS2 UI customization provided, then map to UiCustomization`() {
        val headingColor = "#222222"
        val textColor = "#111111"
        mockkStatic(Color::class)
        every { Color.parseColor(headingColor) } returns -1
        every { Color.parseColor(textColor) } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            headingCustomization = ThreeDS2ToolbarCustomizationDTO(
                headerText = "Heading",
                buttonText = "Cancel",
                textFontSize = 18,
            ),
            labelCustomization = ThreeDS2LabelCustomizationDTO(
                textColor = textColor,
                textFontSize = 12,
                headingTextColor = headingColor,
                headingTextFontSize = 14,
            ),
        )

        val cardComponentConfigurationDTO = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        )

        val checkoutConfiguration = cardComponentConfigurationDTO.toCheckoutConfiguration()
        val threeDS2Configuration = checkoutConfiguration.getActionConfiguration(Adyen3DS2Configuration::class.java)
        val uiCustomization = threeDS2Configuration?.uiCustomization as UiCustomization?

        val toolbar = uiCustomization?.toolbarCustomization
        assertEquals("Heading", toolbar?.headerText)
        assertEquals("Cancel", toolbar?.buttonText)
        assertEquals(18, toolbar?.textFontSize)

        val label = uiCustomization?.labelCustomization
        assertEquals(textColor, label?.textColor)
        assertEquals(12, label?.textFontSize)
        assertEquals(headingColor, label?.headingTextColor)
        assertEquals(14, label?.headingTextFontSize)
    }

    @Test
    fun `when 3DS2 screen and input customization provided, then map to UiCustomization`() {
        val screenBackgroundColor = "#ABCDEF"
        val screenTextColor = "#123456"
        val borderColor = "#654321"
        val inputTextColor = "#0F0F0F"
        mockkStatic(Color::class)
        every { Color.parseColor(screenBackgroundColor) } returns -1
        every { Color.parseColor(screenTextColor) } returns -1
        every { Color.parseColor(borderColor) } returns -1
        every { Color.parseColor(inputTextColor) } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            screenCustomization = ThreeDS2ScreenCustomizationDTO(
                backgroundColor = screenBackgroundColor,
                textColor = screenTextColor,
            ),
            inputCustomization = ThreeDS2InputCustomizationDTO(
                borderColor = borderColor,
                borderWidth = 3,
                cornerRadius = 4,
                textColor = inputTextColor,
            ),
        )

        val cardComponentConfigurationDTO = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        )

        val uiCustomization = cardComponentConfigurationDTO
            .toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val textBoxCustomization = uiCustomization?.textBoxCustomization
        val screenCustomization = uiCustomization?.screenCustomization
        assertEquals(screenBackgroundColor, screenCustomization?.backgroundColor)
        assertEquals(screenTextColor, screenCustomization?.textColor)
        assertEquals(borderColor, textBoxCustomization?.borderColor)
        assertEquals(3, textBoxCustomization?.borderWidth)
        assertEquals(4, textBoxCustomization?.cornerRadius)
        assertEquals(inputTextColor, textBoxCustomization?.textColor)
    }

    @Test
    fun `when 3DS2 button customization provided, then map to all button types`() {
        val primary = ThreeDS2ButtonCustomizationDTO(
            backgroundColor = "#0000FF",
            cornerRadius = 6,
            textColor = "#FFFFFF",
            textFontSize = 16,
        )
        val secondary = ThreeDS2ButtonCustomizationDTO(
            backgroundColor = "#00FF00",
            cornerRadius = 8,
            textColor = "#000000",
            textFontSize = 14,
        )
        mockkStatic(Color::class)
        every { Color.parseColor(any()) } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            primaryButtonCustomization = primary,
            secondaryButtonCustomization = secondary,
        )

        val cardComponentConfigurationDTO = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        )

        val uiCustomization = cardComponentConfigurationDTO
            .toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val primaryTypes = listOf(
            UiCustomization.ButtonType.VERIFY,
            UiCustomization.ButtonType.CONTINUE,
            UiCustomization.ButtonType.NEXT,
            UiCustomization.ButtonType.OPEN_OOB_APP,
        )

        primaryTypes.forEach { type ->
            val button = uiCustomization?.getButtonCustomization(type)
            assertEquals("#0000FF", button?.backgroundColor)
            assertEquals(6, button?.cornerRadius)
            assertEquals("#FFFFFF", button?.textColor)
            assertEquals(16, button?.textFontSize)
        }

        val secondaryTypes = listOf(
            UiCustomization.ButtonType.CANCEL,
            UiCustomization.ButtonType.RESEND,
        )

        secondaryTypes.forEach { type ->
            val button = uiCustomization?.getButtonCustomization(type)
            assertEquals("#00FF00", button?.backgroundColor)
            assertEquals(8, button?.cornerRadius)
            assertEquals("#000000", button?.textColor)
            assertEquals(14, button?.textFontSize)
        }
    }

    @Test
    fun `when input label customization provided, then map input label fields`() {
        val inputLabelColor = "#101010"
        val inputLabelFontSize = 11L
        mockkStatic(Color::class)
        every { Color.parseColor(any()) } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            labelCustomization = ThreeDS2LabelCustomizationDTO(
                inputLabelTextColor = inputLabelColor,
                inputLabelFontSize = inputLabelFontSize,
            )
        )

        val uiCustomization = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        ).toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val labelCustomization = uiCustomization?.labelCustomization
        assertEquals(inputLabelColor, labelCustomization?.inputLabelTextColor)
        assertEquals(inputLabelFontSize.toInt(), labelCustomization?.inputLabelTextFontSize)
    }

    @Test
    fun `when 3DS2 config has requestorAppURL only, then no UI customization is set`() {
        val configuration = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = null,
            )
        )

        val adyen3DS2Configuration = configuration
            .toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)

        assertEquals("https://adyen.com/3ds2", adyen3DS2Configuration?.threeDSRequestorAppURL)
        assertEquals(null, adyen3DS2Configuration?.uiCustomization)
    }

    @Test
    fun `when UI customization provided without requestorAppURL, then map UI only`() {
        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            headingCustomization = ThreeDS2ToolbarCustomizationDTO(
                headerText = "Heading only",
                textFontSize = 20,
            ),
        )

        val configuration = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = null,
                uiCustomization = uiCustomizationDTO,
            )
        )

        val adyen3DS2Configuration = configuration
            .toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)

        val toolbar = (adyen3DS2Configuration?.uiCustomization as UiCustomization?)?.toolbarCustomization
        assertEquals(null, adyen3DS2Configuration?.threeDSRequestorAppURL)
        assertEquals("Heading only", toolbar?.headerText)
        assertEquals(20, toolbar?.textFontSize)
    }

    @Test
    fun `when all UI customizations provided, then all map together`() {
        val headingColor = "#222222"
        val textColor = "#111111"
        val screenBackgroundColor = "#ABCDEF"
        val screenTextColor = "#123456"
        val borderColor = "#654321"
        val inputTextColor = "#0F0F0F"
        val primaryColor = "#0000FF"
        val secondaryColor = "#00FF00"
        mockkStatic(Color::class)
        every { Color.parseColor(any()) } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            headingCustomization = ThreeDS2ToolbarCustomizationDTO(
                headerText = "Heading",
                buttonText = "Cancel",
                textFontSize = 18,
                textColor = headingColor,
            ),
            labelCustomization = ThreeDS2LabelCustomizationDTO(
                textColor = textColor,
                textFontSize = 12,
                headingTextColor = headingColor,
                headingTextFontSize = 14,
                inputLabelTextColor = "#101010",
                inputLabelFontSize = 11,
            ),
            screenCustomization = ThreeDS2ScreenCustomizationDTO(
                backgroundColor = screenBackgroundColor,
                textColor = screenTextColor,
            ),
            inputCustomization = ThreeDS2InputCustomizationDTO(
                borderColor = borderColor,
                borderWidth = 3,
                cornerRadius = 4,
                textColor = inputTextColor,
            ),
            primaryButtonCustomization = ThreeDS2ButtonCustomizationDTO(
                backgroundColor = primaryColor,
                cornerRadius = 6,
                textColor = "#FFFFFF",
                textFontSize = 16,
            ),
            secondaryButtonCustomization = ThreeDS2ButtonCustomizationDTO(
                backgroundColor = secondaryColor,
                cornerRadius = 8,
                textColor = "#000000",
                textFontSize = 14,
            ),
        )

        val uiCustomization = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        ).toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val toolbar = uiCustomization?.toolbarCustomization
        assertEquals("Heading", toolbar?.headerText)
        assertEquals("Cancel", toolbar?.buttonText)
        assertEquals(18, toolbar?.textFontSize)
        assertEquals(headingColor, toolbar?.textColor)

        val label = uiCustomization?.labelCustomization
        assertEquals(textColor, label?.textColor)
        assertEquals(12, label?.textFontSize)
        assertEquals(headingColor, label?.headingTextColor)
        assertEquals(14, label?.headingTextFontSize)
        assertEquals("#101010", label?.inputLabelTextColor)
        assertEquals(11, label?.inputLabelTextFontSize)

        val screen = uiCustomization?.screenCustomization
        assertEquals(screenBackgroundColor, screen?.backgroundColor)
        assertEquals(screenTextColor, screen?.textColor)

        val textBox = uiCustomization?.textBoxCustomization
        assertEquals(borderColor, textBox?.borderColor)
        assertEquals(3, textBox?.borderWidth)
        assertEquals(4, textBox?.cornerRadius)
        assertEquals(inputTextColor, textBox?.textColor)

        val primary = uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.VERIFY)
        assertEquals(primaryColor, primary?.backgroundColor)
        assertEquals(6, primary?.cornerRadius)
        assertEquals("#FFFFFF", primary?.textColor)
        assertEquals(16, primary?.textFontSize)

        val secondary = uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.CANCEL)
        assertEquals(secondaryColor, secondary?.backgroundColor)
        assertEquals(8, secondary?.cornerRadius)
        assertEquals("#000000", secondary?.textColor)
        assertEquals(14, secondary?.textFontSize)
    }

    @Test
    fun `when invalid color is provided, then Color parse error bubbles`() {
        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            headingCustomization = ThreeDS2ToolbarCustomizationDTO(
                textColor = "#INVALID",
            ),
        )

        val configuration = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        )

        try {
            configuration.toCheckoutConfiguration()
        } catch (expected: Exception) {
            assertEquals("hexColorCode must not be null.", expected.message)
        }
    }

    @Test
    fun `when input customization has partial fields, then only provided fields are set`() {
        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            inputCustomization = ThreeDS2InputCustomizationDTO(
                borderWidth = 2,
            )
        )

        val uiCustomization = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        ).toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val textBoxCustomization = uiCustomization?.textBoxCustomization
        val defaultTextBoxCustomization = TextBoxCustomization()
        assertEquals(2, textBoxCustomization?.borderWidth)
        assertEquals(defaultTextBoxCustomization.borderColor, textBoxCustomization?.borderColor)
        assertEquals(defaultTextBoxCustomization.cornerRadius, textBoxCustomization?.cornerRadius)
        assertEquals(defaultTextBoxCustomization.textColor, textBoxCustomization?.textColor)
    }

    @Test
    fun `when screen customization has only background color, then text color remains default`() {
        mockkStatic(Color::class)
        every { Color.parseColor("#F0F0F0") } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            screenCustomization = ThreeDS2ScreenCustomizationDTO(
                backgroundColor = "#F0F0F0",
            )
        )

        val uiCustomization = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        ).toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val screenCustomization = uiCustomization?.screenCustomization
        val defaultScreenCustomization = ScreenCustomization()
        assertEquals("#F0F0F0", screenCustomization?.backgroundColor)
        assertEquals(defaultScreenCustomization.textColor, screenCustomization?.textColor)
    }

    @Test
    fun `when secondary buttons are not provided, then button customization remains default`() {
        mockkStatic(Color::class)
        every { Color.parseColor("#123123") } returns -1

        val uiCustomizationDTO = ThreeDS2UICustomizationDTO(
            primaryButtonCustomization = ThreeDS2ButtonCustomizationDTO(
                backgroundColor = "#123123",
                textFontSize = 14,
            )
        )

        val uiCustomization = createBaseCardComponentConfiguration(
            ThreeDS2ConfigurationDTO(
                requestorAppURL = "https://adyen.com/3ds2",
                uiCustomization = uiCustomizationDTO,
            )
        ).toCheckoutConfiguration()
            .getActionConfiguration(Adyen3DS2Configuration::class.java)
            ?.uiCustomization as UiCustomization?

        val defaultButtonCustomization = ButtonCustomization()
        assertEquals(
            defaultButtonCustomization.backgroundColor,
            uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.CANCEL)?.backgroundColor
        )
        assertEquals(
            defaultButtonCustomization.textColor,
            uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.CANCEL)?.textColor
        )
        assertEquals(
            defaultButtonCustomization.textFontSize,
            uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.CANCEL)?.textFontSize
        )
        assertEquals(
            defaultButtonCustomization.backgroundColor,
            uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.RESEND)?.backgroundColor
        )
        assertEquals(
            defaultButtonCustomization.textColor,
            uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.RESEND)?.textColor
        )
        assertEquals(
            defaultButtonCustomization.textFontSize,
            uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.RESEND)?.textFontSize
        )
        val primary = uiCustomization?.getButtonCustomization(UiCustomization.ButtonType.VERIFY)
        assertEquals("#123123", primary?.backgroundColor)
        assertEquals(14, primary?.textFontSize)
    }
}
