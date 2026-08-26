import Foundation
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
import UIKit
@_spi(AdyenInternal) import Adyen
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif

class DropInPlatformApi: DropInPlatformInterface {
    private let jsonDecoder = JSONDecoder()
    private let checkoutFlutter: CheckoutFlutterInterface
    private let sessionHolder: SessionHolder
    private var dropInComponent: DropInComponent?
    private var deleteStoredPaymentMethodCompletionHandler: ((Bool) -> Void)?
    private var dropInAdvancedFlowDelegate: DropInAdvancedFlowDelegate?
    private var checkBalanceHandler: ((Result<Balance, any Error>) -> Void)?
    private var requestOrderHandler: ((Result<PartialPaymentOrder, any Error>) -> Void)?
    private let dropInWindowManager = DropInWindowManager()

    init(
        checkoutFlutter: CheckoutFlutterInterface,
        sessionHolder: SessionHolder
    ) {
        self.checkoutFlutter = checkoutFlutter
        self.sessionHolder = sessionHolder
        dropInWindowManager.delegate = self
    }

    func showDropInSession(dropInConfigurationDTO: DropInConfigurationDTO) {
        do {
            // Drop-in relies on the delegate to dismiss itself once the session completes. Without it the
            // Drop-in would stay on screen and Flutter would never receive a result, so fail fast instead.
            guard let session = sessionHolder.session,
                  let sessionsDelegate = sessionHolder.sessionDelegate as? DropInSessionsDelegate else {
                throw PlatformError(errorDescription: "Session is not available.")
            }

            let sessionPayment = session.sessionContext.createPayment(fallbackCountryCode: dropInConfigurationDTO.countryCode)
            let adyenContext = try dropInConfigurationDTO.createAdyenContext(payment: sessionPayment)
            let dropInConfiguration = try dropInConfigurationDTO.createDropInConfiguration(payment: sessionPayment)
            var paymentMethods = session.sessionContext.paymentMethods
            if let paymentMethodNames = dropInConfigurationDTO.paymentMethodNames {
                paymentMethods = overridePaymentMethodNames(
                    paymentMethods: paymentMethods,
                    paymentMethodNames: paymentMethodNames
                )
            }
            paymentMethods = applyStoredPaymentMethodsVisibility(
                paymentMethods: paymentMethods,
                showStoredPaymentMethods: dropInConfigurationDTO.showStoredPaymentMethods
            )

            let dropInComponent = DropInComponent(
                paymentMethods: paymentMethods,
                context: adyenContext,
                configuration: dropInConfiguration,
                title: dropInConfigurationDTO.preselectedPaymentMethodTitle
            )

            dropInComponent.delegate = session
            dropInComponent.partialPaymentDelegate = session
            dropInComponent.cardComponentDelegate = self
            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled {
                dropInComponent.storedPaymentMethodsDelegate = self
            }

            // Everything above is built into locals so a rejected presentation cannot replace the
            // references of a Drop-in that is already on screen. They are committed only once the
            // window manager accepted the presentation.
            guard try dropInWindowManager.present(dropInViewController: dropInComponent.viewController) else {
                return
            }

            self.dropInComponent = dropInComponent
            sessionsDelegate.dropInInteractorDelegate = self
        } catch {
            sendSessionError(error: error)
        }
    }

    func showDropInAdvanced(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) {
        do {
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            var paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            if let paymentMethodNames = dropInConfigurationDTO.paymentMethodNames {
                paymentMethods = overridePaymentMethodNames(
                    paymentMethods: paymentMethods,
                    paymentMethodNames: paymentMethodNames
                )
            }

            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(
                paymentMethods: paymentMethods,
                isPartialPaymentSupported: dropInConfigurationDTO.isPartialPaymentSupported
            )
            let filteredPaymentMethods = applyStoredPaymentMethodsVisibility(
                paymentMethods: paymentMethodsWithoutGiftCards,
                showStoredPaymentMethods: dropInConfigurationDTO.showStoredPaymentMethods
            )
            let configuration = try dropInConfigurationDTO.createDropInConfiguration(payment: adyenContext.payment)
            let dropInComponent = DropInComponent(
                paymentMethods: filteredPaymentMethods,
                context: adyenContext,
                configuration: configuration,
                title: dropInConfigurationDTO.preselectedPaymentMethodTitle
            )
            let advancedFlowDelegate = DropInAdvancedFlowDelegate(checkoutFlutter: checkoutFlutter)
            advancedFlowDelegate.dropInInteractorDelegate = self
            dropInComponent.delegate = advancedFlowDelegate
            dropInComponent.cardComponentDelegate = self
            if dropInConfigurationDTO.isPartialPaymentSupported {
                dropInComponent.partialPaymentDelegate = self
            }
            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled {
                dropInComponent.storedPaymentMethodsDelegate = self
            }
            guard try dropInWindowManager.present(dropInViewController: dropInComponent.viewController) else {
                return
            }

            self.dropInComponent = dropInComponent
            dropInAdvancedFlowDelegate = advancedFlowDelegate
        } catch {
            let checkoutEvent = CheckoutEvent(
                type: CheckoutEventType.result,
                data: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            )
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        }
    }
    
    func stopDropIn() throws {
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.result,
            data: PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(resultCode: Constants.resultCodeCancelled)
            )
        )
        finalizeAndDismiss(success: false, completion: { [weak self] in
            self?.checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        })
    }

    func onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsDetailsResult)
    }

    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        deleteStoredPaymentMethodCompletionHandler?(
            deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved
        )
        deleteStoredPaymentMethodCompletionHandler = nil
    }
    
    func onBalanceCheckResult(balanceCheckResponse: String) throws {
        guard let checkBalanceHandler else { return }
        
        do {
            guard let balanceCheckData = balanceCheckResponse.data(using: .utf8) else {
                throw PlatformError(errorDescription: "Failure parsing balance check response.")
            }
            let balance = try jsonDecoder.decode(Balance.self, from: balanceCheckData)
            checkBalanceHandler(.success(balance))
        } catch {
            checkBalanceHandler(.failure(error))
        }
    }
    
    func onOrderRequestResult(orderRequestResponse: String) throws {
        guard let requestOrderHandler else { return }
        
        do {
            guard let orderRequestData = orderRequestResponse.data(using: .utf8) else {
                throw PlatformError(errorDescription: "Failure parsing order request response.")
            }
            let partialPaymentOrder = try jsonDecoder.decode(PartialPaymentOrder.self, from: orderRequestData)
            requestOrderHandler(.success(partialPaymentOrder))
        } catch {
            requestOrderHandler(.failure(error))
        }
    }
    
    func onOrderCancelResult(orderCancelResult: OrderCancelResultDTO) throws {}

    func cleanUpDropIn() {
        dropInWindowManager.cleanUp()
        clearPresentationReferences()
        sessionHolder.reset()
    }
}

extension DropInPlatformApi: DropInWindowManagerDelegate {
    /// The Drop-in window disappeared without a dismissal request, so Flutter still awaits a result.
    func dropInWindowDidDismissUnexpectedly() {
        clearPresentationReferences()
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.result,
            data: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: "Drop-in was dismissed unexpectedly."
            )
        )
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }
}

private extension DropInPlatformApi {
    /// Drops everything tied to a single Drop-in presentation.
    func clearPresentationReferences() {
        dropInComponent = nil
        deleteStoredPaymentMethodCompletionHandler = nil
        (sessionHolder.sessionDelegate as? DropInSessionsDelegate)?.dropInInteractorDelegate = nil
        dropInAdvancedFlowDelegate?.dropInInteractorDelegate = nil
        dropInAdvancedFlowDelegate = nil
        checkBalanceHandler = nil
        requestOrderHandler = nil
    }

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onDropInResultFinished(paymentEventDTO: paymentEventDTO)
        case .action:
            onDropInResultAction(paymentEventDTO: paymentEventDTO)
        case .error:
            onDropInResultError(paymentEventDTO: paymentEventDTO)
        case .update:
            onDropInResultUpdate(paymentEventDTO: paymentEventDTO)
        }
    }

    func onDropInResultFinished(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let isAccepted = resultCode?.isAccepted ?? false
        finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
            let paymentResult = PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(
                    resultCode: resultCode?.rawValue
                )
            )
            let checkoutEvent = CheckoutEvent(type: CheckoutEventType.result, data: paymentResult)
            self?.checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        })
    }

    func onDropInResultAction(paymentEventDTO: PaymentEventDTO) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paymentEventDTO.data as Any, options: [])
            let result = try JSONDecoder().decode(Action.self, from: jsonData)
            dropInComponent?.handle(result)
        } catch {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            let checkoutEvent = CheckoutEvent(type: CheckoutEventType.result, data: paymentResult)
            finalizeAndDismiss(success: false) { [weak self] in
                self?.checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
            }
        }
    }

    func onDropInResultError(paymentEventDTO: PaymentEventDTO) {
        dropInComponent?.stopLoading()

        if paymentEventDTO.error?.dismissDropIn == true || dropInAdvancedFlowDelegate?.isApplePay == true {
            finalizeAndDismiss(success: false) { [weak self] in
                let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: paymentEventDTO.error?.errorMessage)
                let checkoutEvent = CheckoutEvent(type: CheckoutEventType.result, data: paymentResult)
                self?.checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
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
            dropInComponent?.viewController.adyen.topPresenter.present(alertController, animated: true)
        }
    }
    
    func onDropInResultUpdate(paymentEventDTO: PaymentEventDTO) {
        do {
            guard let updatedPaymentMethods = paymentEventDTO.data?[Constants.updatedPaymentMethodsKey] ?? "" else {
                throw PlatformError(errorDescription: "Updated payment methods not provided.")
            }
            
            guard let orderResponse = paymentEventDTO.data?[Constants.orderKey] ?? "" else {
                throw PlatformError(errorDescription: "Order not provided.")
            }
            
            let updatedPaymentMethodsData = try JSONSerialization.data(withJSONObject: updatedPaymentMethods, options: [])
            let paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from: updatedPaymentMethodsData)
            let orderData = try JSONSerialization.data(withJSONObject: orderResponse, options: [])
            let order = try jsonDecoder.decode(PartialPaymentOrder.self, from: orderData)
            try dropInComponent?.reload(with: order, paymentMethods)
        } catch {
            adyenPrint(error.localizedDescription)
        }
    }

    func removeGiftCardPaymentMethods(paymentMethods: PaymentMethods, isPartialPaymentSupported: Bool) -> PaymentMethods {
        if isPartialPaymentSupported {
            return paymentMethods
        }

        let storedPaymentMethods = paymentMethods.stored.filter { !($0.type == PaymentMethodType.giftcard) }
        let paymentMethods = paymentMethods.regular.filter { !($0.type == PaymentMethodType.giftcard) }
        return PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
    }

    func applyStoredPaymentMethodsVisibility(paymentMethods: PaymentMethods, showStoredPaymentMethods: Bool) -> PaymentMethods {
        if showStoredPaymentMethods {
            return paymentMethods
        }
        return PaymentMethods(regular: paymentMethods.regular, stored: [])
    }

    func sendSessionError(error: Error) {
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.result,
            data: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }

    func overridePaymentMethodNames(paymentMethods: PaymentMethods, paymentMethodNames: [String?: String?]) -> PaymentMethods {
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

extension DropInPlatformApi: StoredPaymentMethodsDelegate {
    func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        deleteStoredPaymentMethodCompletionHandler = completion
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.deleteStoredPaymentMethod,
            data: storedPaymentMethod.identifier
        )
        checkoutFlutter.send(
            event: checkoutEvent,
            completion: { _ in }
        )
    }
}

extension DropInPlatformApi: DropInInteractorDelegate {
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        guard let dropInComponent else { return }
        let dropInViewController = dropInComponent.viewController
        dropInComponent.finalizeIfNeeded(with: success) { [weak self] in
            self?.dropInWindowManager.dismiss(
                dropInViewController: dropInViewController,
                animated: true,
                completion: completion
            )
        }
    }
}

extension DropInPlatformApi: PartialPaymentDelegate {
    func checkBalance(with data: Adyen.PaymentComponentData, component: any Adyen.Component, completion: @escaping (Result<Adyen.Balance, any Error>) -> Void) {
        do {
            checkBalanceHandler = completion
            let checkoutEvent = try CheckoutEvent(
                type: CheckoutEventType.balanceCheck,
                data: data.jsonObject.toJsonStringRepresentation()
            )
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        } catch {
            completion(.failure(error))
        }
    }
    
    func requestOrder(for component: any Adyen.Component, completion: @escaping (Result<Adyen.PartialPaymentOrder, any Error>) -> Void) {
        requestOrderHandler = completion
        let checkoutEvent = CheckoutEvent(type: CheckoutEventType.requestOrder)
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }
    
    func cancelOrder(_ order: Adyen.PartialPaymentOrder, component: any Adyen.Component) {
        do {
            let cancelOrderData: [String: Any] = [
                Constants.orderKey: order.jsonObject,
                Constants.shouldUpdatePaymentMethodsKey: false
            ]
            let data = try JSONSerialization.data(withJSONObject: cancelOrderData, options: [])
            let cancelOrderDataString = String(data: data, encoding: .utf8)
            let checkoutEvent = CheckoutEvent(type: CheckoutEventType.cancelOrder, data: cancelOrderDataString)
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        } catch {
            adyenPrint(error.localizedDescription)
        }
    }

}

extension DropInPlatformApi: CardComponentDelegate {
    func didSubmit(lastFour: String, finalBIN: String, component: CardComponent) {}
    
    func didChangeBIN(_ value: String, component: CardComponent) {
        let checkoutEvent = CheckoutEvent(type: CheckoutEventType.binValue, data: value)
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }
    
    func didChangeCardBrand(_ value: [CardBrand]?, component: CardComponent) {
        guard let binLookupData = value else {
            return
        }
        
        let binLookupDataDtoList: [BinLookupDataDTO] = binLookupData.map { cardBrand in
            BinLookupDataDTO(brand: cardBrand.type.rawValue)
        }
        
        let checkoutEvent = CheckoutEvent(type: CheckoutEventType.binLookup, data: binLookupDataDtoList)
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }
}
