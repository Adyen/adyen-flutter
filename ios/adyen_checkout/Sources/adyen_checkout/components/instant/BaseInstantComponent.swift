@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import UIKit

/// Generic base class for payment methods that don't need an embedded Flutter platform view
/// (e.g. Apple Pay, Google Pay, redirect-style instant payment methods). The component is either
/// presented modally (when it has a native UI, like Apple Pay's PassKit sheet) or submitted
/// directly (when it requires no user interaction).
@MainActor
class BaseInstantComponent {
    let componentFlutterApi: ComponentFlutterInterface
    let componentId: String
    private(set) var paymentComponent: CheckoutPaymentComponent?

    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }

    func present(component: CheckoutPaymentComponent) {
        paymentComponent = component
        if component.requiresUserInteraction, let viewController = component.viewController {
            getViewController()?.present(viewController, animated: true)
        } else {
            component.submit()
        }
    }

    func onDispose() {
        paymentComponent = nil
    }

    func sendErrorToFlutterLayer(errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: errorMessage
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }

    func sendFinishedResult(resultCode: String) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(resultCode: resultCode)
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
}
