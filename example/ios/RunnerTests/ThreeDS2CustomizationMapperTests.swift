@_spi(AdyenInternal) import Adyen
@testable import adyen_checkout
import XCTest

#if canImport(AdyenActions)
    import AdyenActions
#endif

#if canImport(Adyen3DS2)
    import Adyen3DS2
#endif

final class ThreeDS2CustomizationMapperTests: XCTestCase {
    func test_uiCustomization_isMappedToAppearanceConfiguration() {
        let uiCustomization = ThreeDS2UICustomizationDTO(
            screenCustomization: ThreeDS2ScreenCustomizationDTO(
                backgroundColor: "#111111",
                textColor: "#222222"
            ),
            headingCustomization: ThreeDS2ToolbarCustomizationDTO(
                backgroundColor: "#333333",
                headerText: "Heading",
                buttonText: "Cancel",
                textColor: "#444444"
            ),
            inputCustomization: ThreeDS2InputCustomizationDTO(
                borderColor: "#555555",
                borderWidth: 2,
                cornerRadius: 4,
                textColor: "#666666"
            ),
            primaryButtonCustomization: ThreeDS2ButtonCustomizationDTO(
                backgroundColor: "#777777",
                textColor: "#888888",
                cornerRadius: 6,
                textFontSize: 16
            ),
            secondaryButtonCustomization: ThreeDS2ButtonCustomizationDTO(
                backgroundColor: "#999999",
                textColor: "#AAAAAA",
                cornerRadius: 8,
                textFontSize: 14
            )
        )

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://example.com/3ds2",
            uiCustomization: uiCustomization
        )

        let threeDSConfig = dto.mapToThreeDS2Configuration()
        let appearance = threeDSConfig.appearanceConfiguration

        let nav = appearance.navigationBarAppearance
        XCTAssertEqual(nav.title, "Heading")
        XCTAssertEqual(nav.cancelButtonTitle, "Cancel")
        assertColor(nav.backgroundColor, equalsHex: "#333333")
        assertColor(nav.textColor, equalsHex: "#444444")

        assertColor(appearance.backgroundColor, equalsHex: "#111111")
        assertColor(appearance.textColor, equalsHex: "#222222")

        let textField = appearance.textFieldAppearance
        assertColor(textField.borderColor, equalsHex: "#555555")
        XCTAssertEqual(textField.borderWidth, 2)
        XCTAssertEqual(textField.cornerRadius, 4)
        assertColor(textField.textColor, equalsHex: "#666666")

        let primary = appearance.buttonAppearance(for: .submit)
        assertColor(primary.backgroundColor, equalsHex: "#777777")
        assertColor(primary.textColor, equalsHex: "#888888")
        XCTAssertEqual(primary.cornerRadius, 6)
        XCTAssertEqual(primary.font.pointSize, 16)

        let secondary = appearance.buttonAppearance(for: .cancel)
        assertColor(secondary.backgroundColor, equalsHex: "#999999")
        assertColor(secondary.textColor, equalsHex: "#AAAAAA")
        XCTAssertEqual(secondary.cornerRadius, 8)
        XCTAssertEqual(secondary.font.pointSize, 14)
    }

    func test_requestorAppURL_only_setsURL_andKeepsDefaultAppearance() {
        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://adyen.com/3ds2",
            uiCustomization: nil
        )

        let threeDSConfig = dto.mapToThreeDS2Configuration()
        let appearance = threeDSConfig.appearanceConfiguration

        XCTAssertEqual(threeDSConfig.requestorAppURL, URL(string: "https://adyen.com/3ds2"))
        XCTAssertNil(appearance.navigationBarAppearance.title)
        XCTAssertNil(appearance.navigationBarAppearance.cancelButtonTitle)
    }

    func test_uiCustomization_withoutRequestorAppURL_setsUIOnly() {
        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: ThreeDS2UICustomizationDTO(
                headingCustomization: ThreeDS2ToolbarCustomizationDTO(
                    headerText: "Heading only"
                )
            )
        )

        let threeDSConfig = dto.mapToThreeDS2Configuration()
        let nav = threeDSConfig.appearanceConfiguration.navigationBarAppearance

        XCTAssertNil(threeDSConfig.requestorAppURL)
        XCTAssertEqual(nav.title, "Heading only")
    }

    func test_inputCustomization_partialBorderWidth_preservesDefaults() {
        let baselineAppearance = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: nil
        ).mapToThreeDS2Configuration().appearanceConfiguration

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://adyen.com/3ds2",
            uiCustomization: ThreeDS2UICustomizationDTO(
                inputCustomization: ThreeDS2InputCustomizationDTO(
                    borderWidth: 2
                )
            )
        )

        let textField = dto.mapToThreeDS2Configuration().appearanceConfiguration.textFieldAppearance

        XCTAssertEqual(textField.borderWidth, 2)
        assertColor(textField.borderColor, equals: baselineAppearance.textFieldAppearance.borderColor)
        XCTAssertEqual(textField.cornerRadius, baselineAppearance.textFieldAppearance.cornerRadius)
        assertColor(textField.textColor, equals: baselineAppearance.textFieldAppearance.textColor)
    }

    func test_screenCustomization_backgroundOnly_preservesTextDefaults() {
        let baselineAppearance = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: nil
        ).mapToThreeDS2Configuration().appearanceConfiguration

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: ThreeDS2UICustomizationDTO(
                screenCustomization: ThreeDS2ScreenCustomizationDTO(
                    backgroundColor: "#F0F0F0"
                )
            )
        )

        let appearance = dto.mapToThreeDS2Configuration().appearanceConfiguration

        assertColor(appearance.backgroundColor, equalsHex: "#F0F0F0")
        assertColor(appearance.textColor, equals: baselineAppearance.textColor)
        assertColor(appearance.tintColor, equals: baselineAppearance.tintColor)
        assertColor(appearance.infoAppearance.textColor, equals: baselineAppearance.infoAppearance.textColor)
    }

    func test_invalidColor_isIgnoredAndDoesNotCrash() {
        let baselineAppearance = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: nil
        ).mapToThreeDS2Configuration().appearanceConfiguration

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://adyen.com/3ds2",
            uiCustomization: ThreeDS2UICustomizationDTO(
                headingCustomization: ThreeDS2ToolbarCustomizationDTO(
                    textColor: "#INVALID"
                )
            )
        )

        let navAppearance = dto.mapToThreeDS2Configuration().appearanceConfiguration.navigationBarAppearance

        assertColor(navAppearance.textColor, equals: baselineAppearance.navigationBarAppearance.textColor)
    }

    func test_secondaryButtonsAbsent_keepDefaults() {
        let baselineAppearance = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: nil
        ).mapToThreeDS2Configuration().appearanceConfiguration

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://adyen.com/3ds2",
            uiCustomization: ThreeDS2UICustomizationDTO(
                primaryButtonCustomization: ThreeDS2ButtonCustomizationDTO(
                    backgroundColor: "#123123",
                    textFontSize: 14
                )
            )
        )

        let appearance = dto.mapToThreeDS2Configuration().appearanceConfiguration
        let cancel = appearance.buttonAppearance(for: .cancel)
        let resend = appearance.buttonAppearance(for: .resend)
        assertColor(cancel.backgroundColor, equals: baselineAppearance.buttonAppearance(for: .cancel).backgroundColor)
        assertColor(cancel.textColor, equals: baselineAppearance.buttonAppearance(for: .cancel).textColor)
        XCTAssertEqual(cancel.font.pointSize, baselineAppearance.buttonAppearance(for: .cancel).font.pointSize)
        assertColor(resend.backgroundColor, equals: baselineAppearance.buttonAppearance(for: .resend).backgroundColor)
        assertColor(resend.textColor, equals: baselineAppearance.buttonAppearance(for: .resend).textColor)
        XCTAssertEqual(resend.font.pointSize, baselineAppearance.buttonAppearance(for: .resend).font.pointSize)

        let primary = appearance.buttonAppearance(for: .submit)
        assertColor(primary.backgroundColor, equalsHex: "#123123")
        XCTAssertEqual(primary.font.pointSize, 14)
    }

    func test_allUICustomizations_mapTogether() {
        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://adyen.com/3ds2",
            uiCustomization: ThreeDS2UICustomizationDTO(
                screenCustomization: ThreeDS2ScreenCustomizationDTO(
                    backgroundColor: "#ABCDEF",
                    textColor: "#123456"
                ),
                headingCustomization: ThreeDS2ToolbarCustomizationDTO(
                    backgroundColor: "#222222",
                    headerText: "Heading",
                    buttonText: "Cancel",
                    textColor: "#111111"
                ),
                labelCustomization: ThreeDS2LabelCustomizationDTO(
                    headingTextColor: "#202020",
                    headingTextFontSize: 14,
                    inputLabelTextColor: "#303030",
                    inputLabelFontSize: 11,
                    textColor: "#101010",
                    textFontSize: 20
                ),
                inputCustomization: ThreeDS2InputCustomizationDTO(
                    borderColor: "#654321",
                    borderWidth: 3,
                    cornerRadius: 4,
                    textColor: "#0F0F0F"
                ),
                primaryButtonCustomization: ThreeDS2ButtonCustomizationDTO(
                    backgroundColor: "#0000FF",
                    textColor: "#FFFFFF",
                    cornerRadius: 6,
                    textFontSize: 16
                ),
                secondaryButtonCustomization: ThreeDS2ButtonCustomizationDTO(
                    backgroundColor: "#00FF00",
                    textColor: "#000000",
                    cornerRadius: 8,
                    textFontSize: 14
                )
            )
        )

        let appearance = dto.mapToThreeDS2Configuration().appearanceConfiguration

        let nav = appearance.navigationBarAppearance
        assertColor(nav.backgroundColor, equalsHex: "#222222")
        assertColor(nav.textColor, equalsHex: "#111111")
        XCTAssertEqual(nav.title, "Heading")
        XCTAssertEqual(nav.cancelButtonTitle, "Cancel")

        let label = appearance.labelAppearance
        assertColor(label.textColor, equalsHex: "#101010")
        XCTAssertEqual(label.font.pointSize, 20)
        assertColor(label.headingTextColor, equalsHex: "#202020")
        XCTAssertEqual(label.headingFont.pointSize, 14)
        assertColor(label.subheadingTextColor, equalsHex: "#303030")
        XCTAssertEqual(label.subheadingFont.pointSize, 11)

        assertColor(appearance.backgroundColor, equalsHex: "#ABCDEF")
        assertColor(appearance.textColor, equalsHex: "#101010")
        assertColor(appearance.infoAppearance.textColor, equalsHex: "#123456")

        let textField = appearance.textFieldAppearance
        assertColor(textField.borderColor, equalsHex: "#654321")
        XCTAssertEqual(textField.borderWidth, 3)
        XCTAssertEqual(textField.cornerRadius, 4)
        assertColor(textField.textColor, equalsHex: "#0F0F0F")

        let primary = appearance.buttonAppearance(for: .submit)
        assertColor(primary.backgroundColor, equalsHex: "#0000FF")
        XCTAssertEqual(primary.cornerRadius, 6)
        assertColor(primary.textColor, equalsHex: "#FFFFFF")
        XCTAssertEqual(primary.font.pointSize, 16)

        let secondary = appearance.buttonAppearance(for: .cancel)
        assertColor(secondary.backgroundColor, equalsHex: "#00FF00")
        XCTAssertEqual(secondary.cornerRadius, 8)
        assertColor(secondary.textColor, equalsHex: "#000000")
        XCTAssertEqual(secondary.font.pointSize, 14)
    }

    func test_labelInputOnly_setsInputFields_keepsOthers() {
        let baselineAppearance = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: nil
        ).mapToThreeDS2Configuration().appearanceConfiguration

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: ThreeDS2UICustomizationDTO(
                labelCustomization: ThreeDS2LabelCustomizationDTO(
                    inputLabelTextColor: "#101010",
                    inputLabelFontSize: 11
                )
            )
        )

        let label = dto.mapToThreeDS2Configuration().appearanceConfiguration.labelAppearance

        assertColor(label.subheadingTextColor, equalsHex: "#101010")
        XCTAssertEqual(label.subheadingFont.pointSize, 11)
        assertColor(label.textColor, equals: baselineAppearance.labelAppearance.textColor)
        XCTAssertEqual(label.font.pointSize, baselineAppearance.labelAppearance.font.pointSize)
        assertColor(label.headingTextColor, equals: baselineAppearance.labelAppearance.headingTextColor)
        XCTAssertEqual(label.headingFont.pointSize, baselineAppearance.labelAppearance.headingFont.pointSize)
    }

    func test_requestorURL_nil_with_screenCustomization_appliesUIOnly() {
        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: ThreeDS2UICustomizationDTO(
                screenCustomization: ThreeDS2ScreenCustomizationDTO(
                    textColor: "#111111"
                )
            )
        )

        let config = dto.mapToThreeDS2Configuration()
        XCTAssertNil(config.requestorAppURL)
        assertColor(config.appearanceConfiguration.textColor, equalsHex: "#111111")
    }

    func test_invalidColor_inInputCustomization_isIgnored() {
        let baselineAppearance = ThreeDS2ConfigurationDTO(
            requestorAppURL: nil,
            uiCustomization: nil
        ).mapToThreeDS2Configuration().appearanceConfiguration

        let dto = ThreeDS2ConfigurationDTO(
            requestorAppURL: "https://adyen.com/3ds2",
            uiCustomization: ThreeDS2UICustomizationDTO(
                inputCustomization: ThreeDS2InputCustomizationDTO(
                    borderColor: "#INVALID"
                )
            )
        )

        let textField = dto.mapToThreeDS2Configuration().appearanceConfiguration.textFieldAppearance

        assertColor(textField.borderColor, equals: baselineAppearance.textFieldAppearance.borderColor)
    }

    private func assertColor(_ color: UIColor?, equalsHex hex: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let color else {
            XCTFail("Color was nil", file: file, line: line)
            return
        }
        guard let expected = UIColor(hex: hex) else {
            XCTFail("Invalid expected color", file: file, line: line)
            return
        }
        XCTAssertTrue(color.isEqualTo(expected), file: file, line: line)
    }
}

private extension UIColor {
    func isEqualTo(_ other: UIColor?) -> Bool {
        guard let other else { return false }
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) < 0.001 && abs(g1 - g2) < 0.001 && abs(b1 - b2) < 0.001 && abs(a1 - a2) < 0.001
    }
}

private extension ThreeDS2CustomizationMapperTests {
    func assertColor(_ color: UIColor?, equals other: UIColor?, file: StaticString = #filePath, line: UInt = #line) {
        guard let color, let other else {
            XCTAssertNil(color, file: file, line: line)
            XCTAssertNil(other, file: file, line: line)
            return
        }
        XCTAssertTrue(color.isEqualTo(other), file: file, line: line)
    }
}
