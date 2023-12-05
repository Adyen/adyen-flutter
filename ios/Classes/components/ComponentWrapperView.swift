class ComponentWrapperView: UIStackView {
    var resizeViewportCallback: () -> Void = {}

    init() {
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        resizeViewportCallback()
    }
}
