@_spi(AdyenInternal) import Adyen

class DropInAdvancedManager: BaseDropInManager {
    private let dropInFlutterApi: DropInFlutterInterface
    private var dropInAdvancedFlowDelegate: DropInAdvancedFlowDelegate?
    private var dropInAdvancedFlowStoredPaymentMethodsDelegate: DropInAdvancedFlowStoredPaymentMethodsDelegate?
    
    init(
        dropInFlutterApi: DropInFlutterInterface
    ) {
        self.dropInFlutterApi = dropInFlutterApi
    }
    
    func showDropIn(configuration: DropInConfigurationDTO, paymentMethodsResponse: String) {
        do {
            guard let viewController = getViewController() else {
                return
            }
            
            let adyenContext = try configuration.createAdyenContext()
            let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethods: paymentMethods)
            let dropInConfiguration = try configuration.mapToDropInConfiguration()
            let dropInComponent = DropInComponent(
                paymentMethods: paymentMethodsWithoutGiftCards,
                context: adyenContext,
                configuration: dropInConfiguration
            )
            dropInAdvancedFlowDelegate = DropInAdvancedFlowDelegate(dropInFlutterApi: dropInFlutterApi, finalizeAndDismiss: finalizeAndDismiss(success:completion:))
            dropInComponent.delegate = dropInAdvancedFlowDelegate
            if configuration.isRemoveStoredPaymentMethodEnabled {
                dropInAdvancedFlowStoredPaymentMethodsDelegate = DropInAdvancedFlowStoredPaymentMethodsDelegate(
                    viewController: viewController,
                    dropInFlutterApi: dropInFlutterApi
                )
                dropInComponent.storedPaymentMethodsDelegate = dropInAdvancedFlowStoredPaymentMethodsDelegate
            }
            self.viewController = viewController
            self.dropInComponent = dropInComponent
            viewController.present(dropInComponent.viewController, animated: true)
        } catch {
            cleanUp()
            sendAdvancedError(error: error)
        }
    }
    
    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        dropInAdvancedFlowStoredPaymentMethodsDelegate?.handleDisableResult(
            isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
    }
    
    func cleanUp() {
        dropInAdvancedFlowDelegate = nil
        dropInAdvancedFlowStoredPaymentMethodsDelegate = nil
        dropInComponent = nil
        viewController = nil
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
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
            let paymentResult = PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(resultCode: resultCode?.rawValue)
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
            let jsonData = try JSONSerialization.data(withJSONObject: paymentEventDTO.actionResponse as Any, options: [])
            let result = try JSONDecoder().decode(Action.self, from: jsonData)
            dropInComponent?.handle(result)
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
        dropInComponent?.stopLoading()

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
            dropInComponent?.finalizeIfNeeded(with: false, completion: {})
            let localizationParameters = (dropInComponent as? Localizable)?.localizationParameters
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
            viewController?.adyen.topPresenter.present(alertController, animated: true)
        }
    }
    
    private func sendAdvancedError(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(
            type: PlatformCommunicationType.result,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        dropInFlutterApi.onDropInAdvancedPlatformCommunication(
            platformCommunicationModel: platformCommunicationModel,
            completion: { _ in }
        )
    }
}
