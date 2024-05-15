@_spi(AdyenInternal) import Adyen

class BaseInstantComponent {
    let componentFlutterApi: ComponentFlutterInterface
    let componentId: String
    var instantPaymentComponent: InstantPaymentComponent?
    var activityIndicatorView: UIActivityIndicatorView?

    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }
    
    func initiatePayment() {
        guard let instantPaymentComponent else {
            return
        }
        
        instantPaymentComponent.initiatePayment()
        showActivityIndicator()
    }
    
    func sendErrorToFlutterLayer(error: Error) {
        let type: PaymentResultEnum
        if let componentError = (error as? ComponentError), componentError == ComponentError.cancelled {
            type = PaymentResultEnum.cancelledByUser
        } else {
            type = PaymentResultEnum.error
        }
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: type,
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
    
    func showActivityIndicator() {
        guard let view = UIApplication.shared.adyen.mainKeyWindow else {
            return
        }
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .gray
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = activityIndicatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailingConstraint = activityIndicatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let topConstraint = activityIndicatorView.topAnchor.constraint(equalTo: view.topAnchor)
        let bottomConstraint = activityIndicatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }
    
    func hideActivityIndicator() {
        activityIndicatorView?.removeFromSuperview()
    }
}
