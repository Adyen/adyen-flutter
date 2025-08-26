@_spi(AdyenInternal) import Adyen
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
import UIKit

// View controller is required to prevent propagating the tap event to the FlutterViewController - https://github.com/flutter/flutter/issues/35784#issuecomment-516243057
class DropInViewController: UIViewController {
    let dropInComponent: DropInComponent
    
    init(dropInComponent: DropInComponent) {
        self.dropInComponent = dropInComponent
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        present(dropInComponent.viewController, animated: true)
    }
}
