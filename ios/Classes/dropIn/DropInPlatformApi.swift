import Foundation
@_spi(AdyenInternal) import Adyen
import AdyenNetworking

class DropInPlatformApi: DropInPlatformInterface {
    private let jsonDecoder = JSONDecoder()
    private let dropInFlutterApi: DropInFlutterInterface
    private let sessionHolder: SessionHolder
    private let configurationMapper = ConfigurationMapper()
    private var viewController: UIViewController?
    private var dropInSessionStoredPaymentMethodsDelegate: DropInSessionsStoredPaymentMethodsDelegate?
    private var dropInAdvancedFlowDelegate: DropInAdvancedFlowDelegate?
    private var dropInAdvancedFlowStoredPaymentMethodsDelegate: DropInAdvancedFlowStoredPaymentMethodsDelegate?
    var dropInComponent: DropInComponent?

    init(
        dropInFlutterApi: DropInFlutterInterface,
        sessionHolder: SessionHolder
    ) {
        self.dropInFlutterApi = dropInFlutterApi
        self.sessionHolder = sessionHolder
    }

    func showDropInSession(dropInConfigurationDTO: DropInConfigurationDTO) {
        do {
            guard let viewController = getViewController() else {
                return
            }

            self.viewController = viewController
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            dropInSessionStoredPaymentMethodsDelegate = DropInSessionsStoredPaymentMethodsDelegate(
                viewController: viewController,
                dropInFlutterApi: dropInFlutterApi
            )
            let dropInConfiguration = try configurationMapper.createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
            let dropInComponent = DropInComponent(
                paymentMethods: sessionHolder.session!.sessionContext.paymentMethods,
                context: adyenContext,
                configuration: dropInConfiguration
            )
            dropInComponent.delegate = sessionHolder.session
            dropInComponent.partialPaymentDelegate = sessionHolder.session
            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled {
                dropInComponent.storedPaymentMethodsDelegate = dropInSessionStoredPaymentMethodsDelegate
            }
            self.dropInComponent = dropInComponent
            self.viewController?.present(dropInComponent.viewController, animated: true)
        } catch {
            sendSessionError(error: error)
        }
    }

    func showDropInAdvanced(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) {
        do {
            guard let viewController = getViewController() else {
                return
            }
            self.viewController = viewController
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            let paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethods: paymentMethods)
            let configuration = try configurationMapper.createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
            let dropInComponent = DropInComponent(paymentMethods: paymentMethodsWithoutGiftCards,
                                                  context: adyenContext,
                                                  configuration: configuration)
            dropInAdvancedFlowDelegate = DropInAdvancedFlowDelegate(dropInFlutterApi: dropInFlutterApi)
            dropInAdvancedFlowDelegate?.dropInInteractorDelegate = self
            dropInComponent.delegate = dropInAdvancedFlowDelegate

            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled == true {
                dropInAdvancedFlowStoredPaymentMethodsDelegate = DropInAdvancedFlowStoredPaymentMethodsDelegate(viewController: viewController,
                                                                                                                dropInFlutterApi: dropInFlutterApi)
                dropInComponent.storedPaymentMethodsDelegate = dropInAdvancedFlowStoredPaymentMethodsDelegate
            }
            self.dropInComponent = dropInComponent
            self.viewController?.present(dropInComponent.viewController, animated: true)
        } catch {
            let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: { _ in })
        }
    }

    func onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsDetailsResult)
    }

    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        dropInSessionStoredPaymentMethodsDelegate?.handleDisableResult(isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
        dropInAdvancedFlowStoredPaymentMethodsDelegate?.handleDisableResult(isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
    }

    func cleanUpDropIn() {
        sessionHolder.reset()
        dropInSessionStoredPaymentMethodsDelegate = nil
        dropInAdvancedFlowDelegate?.dropInInteractorDelegate = nil
        dropInAdvancedFlowDelegate = nil
        dropInAdvancedFlowStoredPaymentMethodsDelegate = nil
        viewController = nil
    }

    private func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onDropInResultFinished(paymentEventDTO: paymentEventDTO)
        case .action:
            onDropInResultAction(paymentEventDTO: paymentEventDTO)
        case .error:
            onDropInResultError(paymentEventDTO: paymentEventDTO)
        }
    }

    private func onDropInResultFinished(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismiss(success: success, completion: { [weak self] in
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.finished, result: PaymentResultModelDTO(resultCode: resultCode?.rawValue))
            self?.dropInFlutterApi.onDropInAdvancedPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: { _ in })
        })
    }

    private func onDropInResultAction(paymentEventDTO: PaymentEventDTO) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paymentEventDTO.actionResponse as Any, options: [])
            let result = try JSONDecoder().decode(Action.self, from: jsonData)
            dropInComponent?.handle(result)
        } catch {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: { _ in })
            finalizeAndDismiss(success: false) {}
        }
    }

    private func onDropInResultError(paymentEventDTO: PaymentEventDTO) {
        dropInComponent?.stopLoading()

        if paymentEventDTO.error?.dismissDropIn == true {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: paymentEventDTO.error?.errorMessage)
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: { _ in })
            finalizeAndDismiss(success: false) {}
        } else {
            dropInComponent?.finalizeIfNeeded(with: false, completion: {})
            let localizationParameters = (dropInComponent as? Localizable)?.localizationParameters
            let title = localizedString(.errorTitle, localizationParameters)
            let alertController = UIAlertController(title: title,
                                                    message: paymentEventDTO.error?.errorMessage,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: localizedString(.dismissButton, localizationParameters), style: .cancel))
            viewController?.adyen.topPresenter.present(alertController, animated: true)
        }
    }

    private func removeGiftCardPaymentMethods(paymentMethods: PaymentMethods) -> PaymentMethods {
        let storedPaymentMethods = paymentMethods.stored.filter { !($0.type == PaymentMethodType.giftcard) }
        let paymentMethods = paymentMethods.regular.filter { !($0.type == PaymentMethodType.giftcard) }
        return PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
    }

    private func sendSessionError(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
        dropInFlutterApi.onDropInSessionPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: { _ in })
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

extension DropInPlatformApi: DropInInteractorDelegate {
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.viewController?.dismiss(animated: true, completion: {
                completion()
            })
        }
    }
}
