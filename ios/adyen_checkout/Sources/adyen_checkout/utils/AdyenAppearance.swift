#if canImport(AdyenUI)
    import AdyenUI
#endif

// TODO: v6 migration - DropInComponent.Style is now package-access. Drop-in styling needs v6 CheckoutTheme.
public enum AdyenAppearance {
    private static var _cardComponentStyle: AdyenUI.FormComponentStyle = .init()
    private static var _blikComponentStyle: AdyenUI.FormComponentStyle = .init()

    public static var cardComponentStyle: AdyenUI.FormComponentStyle {
        get { _cardComponentStyle }
        set { _cardComponentStyle = newValue }
    }

    public static var blikComponentStyle: AdyenUI.FormComponentStyle {
        get { _blikComponentStyle }
        set { _blikComponentStyle = newValue }
    }
}
