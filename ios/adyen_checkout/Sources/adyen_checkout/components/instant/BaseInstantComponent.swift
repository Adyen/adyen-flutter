import Adyen
import UIKit

// TODO: v6 migration - InstantPaymentComponent, PaymentComponentDelegate are now package-access.
@MainActor
class BaseInstantComponent {
    let componentFlutterApi: ComponentFlutterInterface
    let componentId: String
    var activityIndicatorView: UIActivityIndicatorView?

    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }

    func sendErrorToFlutterLayer(error: Error) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: .from(error: error),
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }

    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }
        return rootViewController
    }

    func showActivityIndicator() {
        guard let view = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
        else {
            return
        }
        let activityIndicatorView = UIActivityIndicatorView(style: .large)
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
