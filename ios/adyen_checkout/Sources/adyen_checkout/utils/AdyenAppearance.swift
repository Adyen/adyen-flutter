#if canImport(AdyenUI)
    import AdyenUI
#endif
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif

public enum AdyenAppearance {
    private static var _dropInStyle: DropInComponent.Style = .init()
    private static var _cardComponentStyle: AdyenUI.FormComponentStyle = .init()
    private static var _blikComponentStyle: AdyenUI.FormComponentStyle = .init()

    public static var dropInStyle: DropInComponent.Style {
        get { _dropInStyle }
        set { _dropInStyle = newValue }
    }

    public static var cardComponentStyle: AdyenUI.FormComponentStyle {
        get { _cardComponentStyle }
        set { _cardComponentStyle = newValue }
    }

    public static var blikComponentStyle: AdyenUI.FormComponentStyle {
        get { _blikComponentStyle }
        set { _blikComponentStyle = newValue }
    }
}
