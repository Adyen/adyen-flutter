class ComponentPlatformApi: ComponentPlatformInterface {
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }

    func onAction(actionResponse: [String?: Any?]?) throws {
        guard let jsonActionResponse = actionResponse else { return }
        onActionCallback(jsonActionResponse)
    }
}
