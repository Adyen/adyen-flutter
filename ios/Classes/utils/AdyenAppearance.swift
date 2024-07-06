@_spi(AdyenInternal) import Adyen
import Foundation

/// Describes class that provides customization to Drop-in UI elements.
public protocol AdyenDropInAppearanceProvider: AnyObject {

    /// Implement this method to apply the style to Drop-In.
    /// Uses Drop-In Component Style as an umbrella style.
    static func createDropInStyle() -> Adyen.DropInComponent.Style
}

/// Describes class that provides customization to Component UI elements.
public protocol AdyenComponentAppearanceProvider: AnyObject {

    /// Implement this method to apply the style to the card component.
    /// Uses Form Component Style as an umbrella style.
    static func createCardComponentStyle() -> Adyen.FormComponentStyle
}

extension AdyenDropInAppearanceProvider {
    static func createDropInStyle() -> Adyen.DropInComponent.Style {
        DropInComponent.Style()
    }
}

extension AdyenComponentAppearanceProvider {
    static func createCardComponentStyle() -> Adyen.FormComponentStyle {
        FormComponentStyle()
    }
}

internal class AdyenAppearanceLoader: NSObject {
    private static let expectedClassName = "AdyenAppearance"
    private static let bundleExecutableKey = "CFBundleExecutable"

    static func findDropInStyle() -> Adyen.DropInComponent.Style? {
        let appearanceProviders: [AnyClass?] = findAppearanceProviders()
        let dropInAppearanceProviders = appearanceProviders.compactMap { $0 as? AdyenDropInAppearanceProvider.Type }
        guard let dropInAppearanceProvider = dropInAppearanceProviders.first else {
            return nil
        }
        
        return dropInAppearanceProvider.createDropInStyle()
    }
    
    static func findCardComponentStyle() -> Adyen.FormComponentStyle? {
        let appearanceProviders: [AnyClass?] = findAppearanceProviders()
        let cardComponentAppearanceProviders = appearanceProviders.compactMap { $0 as? AdyenComponentAppearanceProvider.Type }
        guard let cardComponentAppearanceProvider = cardComponentAppearanceProviders.first else {
            return nil
        }
        
        return cardComponentAppearanceProvider.createCardComponentStyle()
    }
    
    private static func findAppearanceProviders() -> [AnyClass?] {
        return Bundle.allBundles
            .compactMap { $0.infoDictionary?[bundleExecutableKey] as? String }
            .map { $0.replacingOccurrences(of: " ", with: "_") }
            .map { $0.replacingOccurrences(of: "-", with: "_") }
            .compactMap { NSClassFromString("\($0).\(expectedClassName)") }
    }
}
