import Foundation

class BasePlatformViewManager<BaseComponent: BasePlatformViewComponent> {
    var currentBaseComponent: BaseComponent?

    func register(baseComponent: BaseComponent) {
        currentBaseComponent = baseComponent
    }

    func updateViewHeight(viewId: Int64) {
        guard currentBaseComponent?.viewId == viewId else { return }
        currentBaseComponent?.notifyHeightChanged()
    }

    func onDispose() {
        currentBaseComponent?.onDispose()
        currentBaseComponent = nil
    }
}
