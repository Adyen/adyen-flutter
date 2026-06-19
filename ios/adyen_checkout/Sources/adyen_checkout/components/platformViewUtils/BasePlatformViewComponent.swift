@_spi(AdyenInternal) import Adyen
import Flutter
import UIKit

class BasePlatformViewComponent: NSObject, FlutterPlatformView, UIScrollViewDelegate {
    let viewId: Int64
    let componentId: String
    let componentFlutterApi: ComponentFlutterInterface
    let componentPlatformApi: ComponentPlatformApi
    let componentWrapperView: ComponentWrapperView

    init(
        viewId: Int64,
        componentId: String,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        self.viewId = viewId
        self.componentId = componentId
        self.componentFlutterApi = componentFlutterApi
        self.componentPlatformApi = componentPlatformApi
        componentWrapperView = .init()
        super.init()

        setupResizeViewportCallback()
    }

    func view() -> UIView {
        componentWrapperView
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset = .zero
    }

    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }

        return rootViewController
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

    func notifyHeightChanged() {
        sendHeightUpdate()
    }

    func componentViewPreferredContentHeight() -> CGFloat? {
        nil
    }

    func additionalViewportSpace() -> CGFloat {
        0
    }

    func disableNativeScrollingAndBouncing(componentView: UIView) {
        let formView = findSubview(in: componentView, ofType: UIScrollView.self)
        formView?.delegate = self
        formView?.bounces = false
        formView?.isScrollEnabled = false
        formView?.alwaysBounceVertical = false
        formView?.contentInsetAdjustmentBehavior = .never
    }

    func findSubview<T: UIView>(in view: UIView, ofType type: T.Type) -> T? {
        if let matchingView = view as? T {
            return matchingView
        }

        for subview in view.subviews {
            if let matchingView = findSubview(in: subview, ofType: type) {
                return matchingView
            }
        }

        return nil
    }

    func onDispose() {}

    private func setupResizeViewportCallback() {
        componentWrapperView.resizeViewportCallback = { [weak self] in
            self?.sendHeightUpdate()
        }
    }

    private func sendHeightUpdate() {
        guard let viewHeight = componentViewPreferredContentHeight() else { return }
        let roundedViewHeight = Int(viewHeight + additionalViewportSpace())
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.resize,
            componentId: componentId,
            data: roundedViewHeight
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
