@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardSessionFlowComponent: BaseCardComponent {
    private let cardSessionFlowDelegate: AdyenSessionDelegate
    private let presentationDelegate: PresentationDelegate
    private var adyenSession: AdyenSession?

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        presentationDelegate = CardSessionFlowPresentationDelegate()
        cardSessionFlowDelegate = CardSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi
        )

        setupCardComponentView(arguments: arguments)
    }

    private func setupCardComponentView(arguments: NSDictionary) {
        do {
            guard let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not found") }
            guard let session = arguments.value(forKey: "session") as? SessionDTO else { throw PlatformError(errorDescription: "Session not found") }
            let sessionConfiguration = try createSessionConfiguration(cardComponentConfiguration: cardComponentConfiguration, session: session)
            AdyenSession.initialize(with: sessionConfiguration, delegate: cardSessionFlowDelegate, presentationDelegate: presentationDelegate) { [weak self] result in
                switch result {
                case let .success(session):
                    self?.adyenSession = session
                    self?.attachComponent(session: session, cardComponentConfiguration: cardComponentConfiguration)
                case let .failure(error):
                    print("ERROR \(error)")
                }
            }
        } catch {}
    }

    private func createSessionConfiguration(cardComponentConfiguration: CardComponentConfigurationDTO, session: SessionDTO) throws -> AdyenSession.Configuration {
        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        return AdyenSession.Configuration(
            sessionIdentifier: session.id,
            initialSessionData: session.sessionData,
            context: adyenContext,
            actionComponent: .init()
        )
    }

    private func attachComponent(session: AdyenSession, cardComponentConfiguration: CardComponentConfigurationDTO) {
        do {
            cardComponent = try buildCardComponent(session: session, cardComponentConfiguration: cardComponentConfiguration)
            guard let cardComponentView = cardComponent?.viewController.view else { throw PlatformError(errorDescription: "Failed to get card component view") }
            attachCardView(cardComponentView: cardComponentView)
        } catch {
            print("Error")
        }
    }

    private func buildCardComponent(session: AdyenSession, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        let paymentMethods = session.sessionContext.paymentMethods
        guard let cardPaymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else { throw PlatformError(errorDescription: "Cannot find card payment method") }
        let cardComponent = try CardComponent(paymentMethod: cardPaymentMethod,
                                              context: cardComponentConfiguration.createAdyenContext(),
                                              configuration: cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration())
        cardComponent.delegate = session
        return cardComponent
    }
}
