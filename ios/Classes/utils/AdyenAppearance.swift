@_spi(AdyenInternal) import Adyen
import Foundation

/// Describes class that provides customization to Adyen UI elements.
public protocol AdyenAppearanceProvider: AnyObject {

    /// Implement this method to apply the style to Drop-In.
    /// Uses Drop-In Component Style as an umbrella style.
    static func createDropInStyle() -> DropInComponent.Style?
    
    /// Implement this method to apply the style to the card component.
    /// Uses Form Component Style as an umbrella style.
    static func createCardComponentStyle() -> FormComponentStyle?

}

internal class AdyenAppearanceLoader: NSObject {
    private static let expectedClassName = "AdyenAppearance"
    private static let bundleExecutableKey = "CFBundleExecutable"

    static func findDropInStyle() -> Adyen.DropInComponent.Style? {
        let appearanceProvider = findAppearanceProvider()
        return appearanceProvider?.createDropInStyle()
    }
    
    static func findCardComponentStyle() -> Adyen.FormComponentStyle? {
        let appearanceProvider = findAppearanceProvider()
        return appearanceProvider?.createCardComponentStyle()
    }
    
    private static func findAppearanceProvider() -> AdyenAppearanceProvider.Type? {
        let appearanceProviders: [AdyenAppearanceProvider.Type] = Bundle.allBundles
            .compactMap { $0.infoDictionary?[bundleExecutableKey] as? String }
            .map { $0.replacingOccurrences(of: " ", with: "_") }
            .map { $0.replacingOccurrences(of: "-", with: "_") }
            .compactMap { NSClassFromString("\($0).\(expectedClassName)") }
            .compactMap { $0 as? AdyenAppearanceProvider.Type }
        
        guard let appearanceProvider = appearanceProviders.first else {
            adyenPrint("AdyenAppearance: class not linked or does not conform to AdyenAppearanceProvider protocol")
            return nil
        }
        
        return appearanceProvider
    }
}
