class ComponentPlatformApi: ComponentPlatformInterface {
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }
    var onUpdateViewHeightCallback: () -> Void = {  }

    func onAction(actionResponse: [String?: Any?]?) throws {
        guard let jsonActionResponse = actionResponse else { return }
        onActionCallback(jsonActionResponse)
    }
    
    func updateViewHeight(viewId: Int64) throws {
        onUpdateViewHeightCallback()
    }
}
