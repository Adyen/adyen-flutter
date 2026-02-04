@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout

import Flutter

#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif

class CardAdvancedComponent: BaseCardComponent {
    private var actionComponentDelegate: ActionComponentDelegate?
    private var actionComponent: CheckoutActionComponent?
    private var presentationDelegate: PresentationDelegate?
    private var componentDelegate: PaymentComponentDelegate?

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )

        actionComponentDelegate = ComponentActionHandler(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId,
            finalizeCallback: finalizeAndDismiss(success:completion:)
        )
        setupCardComponentView()
        setupFinalizeComponentCallback()
    }

    private func setupCardComponentView() {
        Task {
            do {
                let configuration = try CheckoutConfiguration(
                    environment: cardComponentConfiguration!.environment.mapToEnvironment(),
                    amount: cardComponentConfiguration!.amount!.mapToAmount(),
                    clientKey: cardComponentConfiguration!.clientKey,
                    analyticsConfiguration: .init()
                ) {
                }.onSubmit { data, handler in
                    
                }.onAdditionalDetails { data, handler in
                    
                }.onError { error in
                    
                }.onComplete { result in
                    
                }
                
                let wrappedJSON = "{\"paymentMethods\":[\(paymentMethod)]}"
                guard let jsonData = wrappedJSON.data(using: .utf8) else {
                    throw PlatformError(errorDescription: "Failed to encode payment methods")
                }
                let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: jsonData)
                let adyenCheckout = try await Checkout.setup(with: paymentMethods, configuration: configuration)
                guard let paymentMethodString = paymentMethod else { throw PlatformError(errorDescription: "Payment method not found") }
                let cardPaymentMethod = try JSONDecoder().decode(CardPaymentMethod.self, from: Data(paymentMethodString.utf8))
                let cardComponent = try buildCardComponent(adyenCheckout: adyenCheckout, cardPaymentMethod: cardPaymentMethod)
                showCardComponent(cardComponent: cardComponent)
            } catch {
                sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
            }
        }
            
            
//            let cardComponent = try setupCardComponent()
//            actionComponent = buildActionComponent(adyenContext: cardComponent.context)
//            showCardComponent(cardComponent: cardComponent)
//            componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
//                self?.onAction(actionResponse: jsonActionResponse)
//            }
//            componentPlatformApi.onErrorCallback = { [weak self] error in
//                self?.cardComponent?.stopLoading()
//                self?.sendErrorToFlutterLayer(errorMessage: error?.errorMessage ?? "")
//            }
//        } catch {
//            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
//        }
    }

//    private func setupCardComponent() throws -> CardComponent {
//        componentDelegate = CardAdvancedFlowDelegate(
//            componentFlutterApi: componentFlutterApi,
//            componentId: componentId
//        )
//        return try buildCardComponent(
//            paymentMethodString: paymentMethod,
//            isStoredPaymentMethod: isStoredPaymentMethod,
//            cardComponentConfiguration: cardComponentConfiguration,
//            componentDelegate: componentDelegate,
//            cardDelegate: self
//        )
//    }

    private func buildActionComponent(adyenContext: AdyenContext) -> CheckoutActionComponent {
        var configuration = CheckoutActionComponent.Configuration()
        if let threeDS2Config = cardComponentConfiguration?.threeDS2ConfigurationDTO {
            configuration.threeDS = threeDS2Config.mapToThreeDS2Configuration()
        }
        let actionComponent = CheckoutActionComponent(context: adyenContext, configuration: configuration)
        actionComponent.delegate = actionComponentDelegate
        actionComponent.presentationDelegate = getViewController()
        return actionComponent
    }

    private func onAction(actionResponse: [String?: Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupFinalizeComponentCallback() {
        componentPlatformApi.onFinishCallback = { [weak self] paymentEvent in
            let resultCode = ResultCode(rawValue: paymentEvent.result ?? "")
            let isAccepted = resultCode?.isAccepted ?? false
            self?.finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
                let componentCommunicationModel = ComponentCommunicationModel(
                    type: ComponentCommunicationType.result,
                    componentId: self?.componentId ?? "",
                    paymentResult: PaymentResultDTO(
                        type: PaymentResultEnum.finished,
                        result: PaymentResultModelDTO(resultCode: resultCode?.rawValue)
                    )
                )
                self?.componentFlutterApi.onComponentCommunication(
                    componentCommunicationModel: componentCommunicationModel,
                    completion: { _ in }
                )
            })
        }
    }
}
