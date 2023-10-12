import Flutter
@_spi(AdyenInternal)
import Adyen
import AdyenNetworking

class CardComponentViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }

    /// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class FLNativeView: NSObject, FlutterPlatformView, PaymentComponentDelegate {
    func didSubmit(_ data: Adyen.PaymentComponentData, from component: Adyen.PaymentComponent) {
        
    }
    
    func didFail(with error: Error, from component: Adyen.PaymentComponent) {
        
    }
    
    private var _view: UIView
    private var cardComponent : CardComponent?
    private var rootViewController : UIViewController?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        
        // iOS views can be created here
        createNativeView(view: _view, args: args as! NSDictionary)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView, args: NSDictionary){
        _view.backgroundColor = UIColor.blue
       
        
        do {
            
            let clientKey = args.value(forKey: "clientKey") as! String
            let paymentMethodsResponse = args.value(forKey: "paymentMethods") as! String
            
            let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let component = try cardComponent(from: paymentMethods, clientKey: clientKey)
            component.delegate = self
            self.cardComponent = component
            
            rootViewController = getViewController()
            rootViewController?.addChild(component.viewController)
            //component.viewController.view.frame = .zero
            component.viewController.view.frame = CGRect(x:0.0, y:0.0, width: 0, height:0)

            _view.addSubview(component.viewController.view)
            

        } catch {
        }

        
        
    }
    
    private func cardComponent(from paymentMethods: PaymentMethods, clientKey: String) throws -> CardComponent {
        let context = try APIContext(environment: Adyen.Environment.test, clientKey: clientKey)
        let adyenContext = AdyenContext(apiContext: context,
                            payment: Payment(amount: Amount(value: 2100, currencyCode: "EUR"), countryCode: "NL"),
                            analyticsConfiguration: AnalyticsConfiguration())

        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else {
            throw PlatformError(errorDescription: "error")
        }

        let component = CardComponent(paymentMethod: paymentMethod,
                                      context: adyenContext
                                )
        component.cardComponentDelegate = self
        return component
    }
    
    private func viewController(for component: PresentableComponent) -> UIViewController {
        guard component.requiresModalPresentation else {
            return component.viewController
        }
        
        let navigation = UINavigationController(rootViewController: component.viewController)
        component.viewController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel,
                                                                          target: self,
                                                                          action: #selector(cancelPressed))
        return navigation
    }
    
    @objc private func cancelPressed() {
        cardComponent?.cancelIfNeeded()
    }
    
    
    private func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            // TODO: - We need to discuss how the SDK should react if a DropInNavigationController is already displayed
            if type == "DropInNavigationController" {
                return nil
            } else {
                rootViewController = presentedViewController
            }
        }

        return rootViewController
    }
  
}

extension FLNativeView: CardComponentDelegate {

    func didSubmit(lastFour: String, finalBIN: String, component: CardComponent) {
        print("Card used: **** **** **** \(lastFour)")
        print("Final BIN: \(finalBIN)")
    }

    internal func didChangeBIN(_ value: String, component: CardComponent) {
        print("Current BIN: \(value)")
    }

    internal func didChangeCardBrand(_ value: [CardBrand]?, component: CardComponent) {
        print("Current card type: \((value ?? []).reduce("") { "\($0), \($1)" })")
    }
}

extension FLNativeView: AdyenSessionDelegate {
    
    func didComplete(with result: AdyenSessionResult, component: Component, session: AdyenSession) {
    }

    func didFail(with error: Error, from component: Component, session: AdyenSession) {
    }

    func didOpenExternalApplication(component: ActionComponent, session: AdyenSession) {}

}

extension FLNativeView: PresentationDelegate {
    internal func present(component: PresentableComponent) {
        let componentViewController = viewController(for: component)

    }
}
