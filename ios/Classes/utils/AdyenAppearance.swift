import Adyen

public enum AdyenAppearance {
   private static var _dropInStyle: Adyen.DropInComponent.Style = Adyen.DropInComponent.Style()
   private static var _cardComponentStyle: Adyen.FormComponentStyle = Adyen.FormComponentStyle()

   public static var dropInStyle: Adyen.DropInComponent.Style {
      get { return _dropInStyle }
      set { _dropInStyle = newValue }
   }

   public static var cardComponentStyle: Adyen.FormComponentStyle {
      get { return _cardComponentStyle }
      set { _cardComponentStyle = newValue }
   }
}
