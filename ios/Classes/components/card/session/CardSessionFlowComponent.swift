@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardSessionFlowComponent: NSObject, FlutterPlatformView {
    private let componentFlutterApi: ComponentFlutterApi
    private let componentPlatformApi: ComponentPlatformApi
    private let componentWrapperView: ComponentWrapperView
    private let cardSessionFlowDelegate: AdyenSessionDelegate
    private let presentationDelegate: PresentationDelegate
    private let configurationMapper: ConfigurationMapper
    private let initialFrame: CGRect

    private var adyenSession: AdyenSession?
    private var cardComponent: CardComponent?
    private var actionComponent: AdyenActionComponent?
    private var rootViewController: UIViewController?

    init(
        frame: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        componentPlatformApi = ComponentPlatformApi()
        presentationDelegate = CardSessionFlowPresentationDelegate()
        cardSessionFlowDelegate = CardSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
        componentWrapperView = .init()
        configurationMapper = ConfigurationMapper()
        initialFrame = frame
        super.init()

        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: binaryMessenger, api: componentPlatformApi)
        setupCallbacks()
        setupCardView(arguments: arguments)
    }

    func view() -> UIView {
        return componentWrapperView
    }

    private func setupCallbacks() {
        componentWrapperView.resizeViewportCallback = {
            var viewHeight = Double(round(100 * (self.cardComponent?.viewController.preferredContentSize.height ?? 0)) / 100)
            viewHeight += 32 // TODO: adjust view by preventing clamping scroll to prevent bottom view overscroll
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: viewHeight), completion: { _ in })
        }
    }

    private func setupCardView(arguments: NSDictionary) {
        do {
            guard let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not provided") }
            guard let session = arguments.value(forKey: "session") as? SessionDTO else { throw PlatformError(errorDescription: "Session not provided") }
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
        } catch {
            
        }
    }

    private func disableNativeScrollingAndBouncing(formView: UIScrollView?) {
        formView?.bounces = false
        formView?.isScrollEnabled = false
        formView?.alwaysBounceVertical = false
        formView?.contentInsetAdjustmentBehavior = .never
    }

    private func createSessionConfiguration(cardComponentConfiguration: CardComponentConfigurationDTO, session: SessionDTO) throws -> AdyenSession.Configuration {
        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        return AdyenSession.Configuration(
            sessionIdentifier: session.id,
            initialSessionData: session.sessionData,
            context: adyenContext,
            actionComponent: .init(
                threeDS: .init(
                    // TODO: init threeDS
                )
            )
        )
    }

    private func attachComponent(session: AdyenSession, cardComponentConfiguration: CardComponentConfigurationDTO) {
        do {
            let component = try buildCardComponent(session: session, cardComponentConfiguration: cardComponentConfiguration)
            cardComponent = component
            guard let cardView = component.viewController.view else { throw PlatformError(errorDescription: "") }

            let formView = cardView.subviews[0].subviews[0] as? UIScrollView
            disableNativeScrollingAndBouncing(formView: formView)

            componentWrapperView.addSubview(cardView)

            adjustCardComponentLayout(cardView: cardView)
        } catch {
            print("Error")
            // self.presentAlert(with: error)
        }
    }

    private func buildCardComponent(session: AdyenSession, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        let paymentMethods = session.sessionContext.paymentMethods
        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else {
            throw PlatformError(errorDescription: "Cannot find card payment method")
        }

        let component = try CardComponent(paymentMethod: paymentMethod,
                                          context: cardComponentConfiguration.createAdyenContext(),
                                          configuration: cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration())
        component.delegate = session
        return component
    }

    private func adjustCardComponentLayout(cardView: UIView) {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = cardView.leadingAnchor.constraint(equalTo: componentWrapperView.leadingAnchor)
        let trailingConstraint = cardView.trailingAnchor.constraint(equalTo: componentWrapperView.trailingAnchor)
        let topConstraint = cardView.topAnchor.constraint(equalTo: componentWrapperView.topAnchor)
        let bottomConstraint = cardView.bottomAnchor.constraint(equalTo: componentWrapperView.bottomAnchor)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
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
