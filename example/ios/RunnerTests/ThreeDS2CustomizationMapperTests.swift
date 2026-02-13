@_spi(AdyenInternal) import Adyen
@testable import adyen_checkout
import AdyenActions
import Adyen3DS2
import XCTest

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
