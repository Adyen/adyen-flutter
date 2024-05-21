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
        let appearanceProvider: AdyenDropInAppearanceProvider.Type? = findAppearanceProvider(ofType: AdyenDropInAppearanceProvider.self) as? AdyenDropInAppearanceProvider.Type? ?? nil
        return appearanceProvider?.createDropInStyle()
    }
    
    static func findCardComponentStyle() -> Adyen.FormComponentStyle? {
        let appearanceProvider: AdyenComponentAppearanceProvider.Type? = findAppearanceProvider(ofType: AdyenComponentAppearanceProvider.self) as? AdyenComponentAppearanceProvider.Type? ?? nil
        return appearanceProvider?.createCardComponentStyle()
    }
    
    private static func findAppearanceProvider<T>(ofType type: T.Type) -> T? {
        let appearanceProviders: [T] = Bundle.allBundles
            .compactMap { $0.infoDictionary?[bundleExecutableKey] as? String }
            .map { $0.replacingOccurrences(of: " ", with: "_") }
            .map { $0.replacingOccurrences(of: "-", with: "_") }
            .compactMap { NSClassFromString("\($0).\(expectedClassName)") }
            .compactMap { $0 as? T }
        
        guard let appearanceProvider = appearanceProviders.first else {
            adyenPrint("AdyenAppearance: class not linked or does not conform to AdyenDropInAppearanceProvider or AdyenComponentAppearanceProvider protocol")
            return nil
        }
        
        return appearanceProvider
    }
}
