import Adyen

public enum AdyenAppearance {
    private static var _dropInStyle: Adyen.DropInComponent.Style = .init()
    private static var _cardComponentStyle: Adyen.FormComponentStyle = .init()

    public static var dropInStyle: Adyen.DropInComponent.Style {
        get { _dropInStyle }
        set { _dropInStyle = newValue }
    }

    public static var cardComponentStyle: Adyen.FormComponentStyle {
        get { _cardComponentStyle }
        set { _cardComponentStyle = newValue }
    }
}
