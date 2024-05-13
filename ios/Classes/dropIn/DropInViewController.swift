@_spi(AdyenInternal) import Adyen

//View controller is required to prevent propagating the tap event to the FlutterViewController - https://github.com/flutter/flutter/issues/35784#issuecomment-516243057
class DropInViewController: UIViewController {
    var dropInComponent: DropInComponent?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func viewDidAppear(_ animated: Bool) {
        guard let dropInComponent = dropInComponent else {
            return
        }
        
        view.isUserInteractionEnabled = false
        present(dropInComponent.viewController, animated: true)
    }
}
