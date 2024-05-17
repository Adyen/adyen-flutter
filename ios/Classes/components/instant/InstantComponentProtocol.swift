protocol InstantComponentProtocol {
    func initiatePayment()
    func finalizeCallback(success: Bool, completion: @escaping (() -> Void))
    func onDispose()
}
