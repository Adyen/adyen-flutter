class ComponentPlatformApi : ComponentPlatformInterface {
    var onActionCallback : ([String? : Any?]) -> Void
    
    init(onActionCallback: @escaping ([String? : Any?]) -> Void) {
        self.onActionCallback = onActionCallback
    }
    
    func onAction(actionResponse: [String? : Any?]?) throws {
        print("ON ACTION")
            
            guard let jsonActionResponse = actionResponse else {
                return
            }
        
            onActionCallback(jsonActionResponse)
            
        
    }
}
