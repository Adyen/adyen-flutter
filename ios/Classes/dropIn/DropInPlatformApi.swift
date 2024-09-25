import Foundation
@_spi(AdyenInternal) import Adyen
import AdyenNetworking

class DropInPlatformApi: DropInPlatformInterface {
    private let jsonDecoder = JSONDecoder()
    private let dropInFlutterApi: DropInFlutterInterface
    private let sessionHolder: SessionHolder
    private var hostViewController: UIViewController?
    private var dropInViewController: DropInViewController?
    private var dropInSessionStoredPaymentMethodsDelegate: DropInSessionsStoredPaymentMethodsDelegate?
    private var dropInAdvancedFlowDelegate: DropInAdvancedFlowDelegate?
    private var dropInAdvancedFlowStoredPaymentMethodsDelegate: DropInAdvancedFlowStoredPaymentMethodsDelegate?

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
            
            guard let session = sessionHolder.session else {
                sendSessionError(error: PlatformError(errorDescription: "Session is not available."))
                return
            }

            hostViewController = viewController
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            dropInSessionStoredPaymentMethodsDelegate = DropInSessionsStoredPaymentMethodsDelegate(
                viewController: viewController,
                dropInFlutterApi: dropInFlutterApi
            )
            let payment = session.sessionContext.payment ?? adyenContext.payment
            let dropInConfiguration = try dropInConfigurationDTO.createDropInConfiguration(payment: payment)
            var paymentMethods = session.sessionContext.paymentMethods
            if let paymentMethodNames = dropInConfigurationDTO.paymentMethodNames {
                paymentMethods = overridePaymentMethodNames(
                    paymentMethods: paymentMethods,
                    paymentMethodNames: paymentMethodNames
                )
            }
            
            let dropInComponent = DropInComponent(
                paymentMethods: paymentMethods,
                context: adyenContext,
                configuration: dropInConfiguration,
                title: dropInConfigurationDTO.preselectedPaymentMethodTitle
            )
            dropInComponent.delegate = sessionHolder.session
            dropInComponent.partialPaymentDelegate = sessionHolder.session
            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled {
                dropInComponent.storedPaymentMethodsDelegate = dropInSessionStoredPaymentMethodsDelegate
            }
            
            let dropInViewController = DropInViewController(dropInComponent: dropInComponent)
            dropInViewController.modalPresentationStyle = .overCurrentContext
            self.dropInViewController = dropInViewController
            self.hostViewController?.present(dropInViewController, animated: false)
        } catch {
            sendSessionError(error: error)
        }
    }

    func showDropInAdvanced(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) {
        do {
            guard let viewController = getViewController() else {
                return
            }
            
            hostViewController = viewController
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            var paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            if let paymentMethodNames = dropInConfigurationDTO.paymentMethodNames {
                paymentMethods = overridePaymentMethodNames(
                    paymentMethods: paymentMethods,
                    paymentMethodNames: paymentMethodNames
                )
            }
            
            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethods: paymentMethods)
            let configuration = try dropInConfigurationDTO.createDropInConfiguration(payment: adyenContext.payment)
            let dropInComponent = DropInComponent(
                paymentMethods: paymentMethodsWithoutGiftCards,
                context: adyenContext,
                configuration: configuration,
                title: dropInConfigurationDTO.preselectedPaymentMethodTitle
            )
            dropInAdvancedFlowDelegate = DropInAdvancedFlowDelegate(dropInFlutterApi: dropInFlutterApi)
            dropInAdvancedFlowDelegate?.dropInInteractorDelegate = self
            dropInComponent.delegate = dropInAdvancedFlowDelegate
            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled == true {
                dropInAdvancedFlowStoredPaymentMethodsDelegate = DropInAdvancedFlowStoredPaymentMethodsDelegate(
                    viewController: viewController,
                    dropInFlutterApi: dropInFlutterApi
                )
                dropInComponent.storedPaymentMethodsDelegate = dropInAdvancedFlowStoredPaymentMethodsDelegate
            }
            let dropInViewController = DropInViewController(dropInComponent: dropInComponent)
            dropInViewController.modalPresentationStyle = .overCurrentContext
            self.dropInViewController = dropInViewController
            self.hostViewController?.present(dropInViewController, animated: false)
        } catch {
            let platformCommunicationModel = PlatformCommunicationModel(
                type: PlatformCommunicationType.result,
                paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            )
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: platformCommunicationModel,
                completion: { _ in }
            )
        }
    }

    func onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsDetailsResult)
    }

    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        dropInSessionStoredPaymentMethodsDelegate?.handleDisableResult(
            isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
        dropInAdvancedFlowStoredPaymentMethodsDelegate?.handleDisableResult(
            isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
    }
    
    func onBalanceCheckResult(balanceCheckResponse: String) throws {
        
    }
    
    func onOrderRequestResult(orderRequestResponse: String) throws {
        
    }
    

    func cleanUpDropIn() {
        sessionHolder.reset()
        dropInSessionStoredPaymentMethodsDelegate = nil
        dropInAdvancedFlowDelegate?.dropInInteractorDelegate = nil
        dropInAdvancedFlowDelegate = nil
        dropInAdvancedFlowStoredPaymentMethodsDelegate = nil
        dropInViewController = nil
        hostViewController = nil
    }

    private func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onDropInResultFinished(paymentEventDTO: paymentEventDTO)
        case .action:
            onDropInResultAction(paymentEventDTO: paymentEventDTO)
        case .error:
            onDropInResultError(paymentEventDTO: paymentEventDTO)
        case .update:
            return
        }
    }

    private func onDropInResultFinished(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let isAccepted = resultCode?.isAccepted ?? false
        finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
            let paymentResult = PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(
                    resultCode: resultCode?.rawValue)
            )
            self?.dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: PlatformCommunicationModel(
                    type: PlatformCommunicationType.result,
                    paymentResult: paymentResult
                ),
                completion: { _ in }
            )
        })
    }

    private func onDropInResultAction(paymentEventDTO: PaymentEventDTO) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paymentEventDTO.data as Any, options: [])
            let result = try JSONDecoder().decode(Action.self, from: jsonData)
            dropInViewController?.dropInComponent.handle(result)
        } catch {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: PlatformCommunicationModel(
                    type: PlatformCommunicationType.result,
                    paymentResult: paymentResult
                ),
                completion: { _ in }
            )
            finalizeAndDismiss(success: false) {}
        }
    }

    private func onDropInResultError(paymentEventDTO: PaymentEventDTO) {
        dropInViewController?.dropInComponent.stopLoading()

        if paymentEventDTO.error?.dismissDropIn == true || dropInAdvancedFlowDelegate?.isApplePay == true {
            finalizeAndDismiss(success: false) { [weak self] in
                let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: paymentEventDTO.error?.errorMessage)
                self?.dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                    platformCommunicationModel: PlatformCommunicationModel(
                        type: PlatformCommunicationType.result,
                        paymentResult: paymentResult
                    ),
                    completion: { _ in }
                )
            }
        } else {
            dropInViewController?.dropInComponent.finalizeIfNeeded(with: false, completion: {})
            let localizationParameters = (dropInViewController?.dropInComponent as? Localizable)?.localizationParameters
            let title = localizedString(.errorTitle, localizationParameters)
            let alertController = UIAlertController(
                title: title,
                message: paymentEventDTO.error?.errorMessage,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(
                title: localizedString(.dismissButton, localizationParameters),
                style: .cancel
            ))
            hostViewController?.adyen.topPresenter.present(alertController, animated: true)
        }
    }

    private func removeGiftCardPaymentMethods(paymentMethods: PaymentMethods) -> PaymentMethods {
        let storedPaymentMethods = paymentMethods.stored.filter { !($0.type == PaymentMethodType.giftcard) }
        let paymentMethods = paymentMethods.regular.filter { !($0.type == PaymentMethodType.giftcard) }
        return PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
    }

    private func sendSessionError(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(
            type: PlatformCommunicationType.result,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        dropInFlutterApi.onDropInSessionPlatformCommunication(
            platformCommunicationModel: platformCommunicationModel,
            completion: { _ in }
        )
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
    
    private func overridePaymentMethodNames(paymentMethods: PaymentMethods, paymentMethodNames: [String?: String?]) -> PaymentMethods {
        var paymentMethodsWithAdjustedNames = paymentMethods
        for paymentMethodNamePair in paymentMethodNames {
            if let paymentMethodRawValue = paymentMethodNamePair.key,
               let paymentMethodType = PaymentMethodType(rawValue: paymentMethodRawValue),
               let paymentMethodName = paymentMethodNamePair.value {
                paymentMethodsWithAdjustedNames.overrideDisplayInformation(
                    ofRegularPaymentMethod: paymentMethodType,
                    with: .init(title: paymentMethodName)
                )
            }
        }
        
        return paymentMethodsWithAdjustedNames
    }
}

extension DropInPlatformApi: DropInInteractorDelegate {
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        dropInViewController?.dropInComponent.finalizeIfNeeded(with: success) { [weak self] in
            self?.hostViewController?.dismiss(animated: true, completion: {
                completion()
            })
        }
    }
}
