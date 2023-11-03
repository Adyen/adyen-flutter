class ComponentWrapperView : UIStackView {
    var resizeViewportCallback : () -> Void
    
    init(resizeViewport: @escaping () -> Void) {
        self.resizeViewportCallback = resizeViewport
        
        super.init(frame: .zero)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        resizeViewportCallback()
    }
}
