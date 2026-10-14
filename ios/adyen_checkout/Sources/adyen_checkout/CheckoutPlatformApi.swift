import Adyen
import AdyenActions
import AdyenCard
import AdyenCheckout
import AdyenComponents
import AdyenEncryption
import AdyenSession
import Flutter
import Foundation
import UIKit

// swiftlint:disable type_body_length
@MainActor
final class CheckoutPlatformApi: CheckoutHostApi {
    private let callbacksApi: CheckoutCallbacksFlutterApi
    private let actionOnlyApi: ActionOnlyFlutterApi
    private let holder: CheckoutHolder
    private let events: ComponentPlatformEventHandler
    private let registry: CheckoutComponentRegistry
    private var presentationDelegates: [String: PresentationDelegateProxy] = [:]
    private var dropInComponents: [String: CheckoutDropInComponent] = [:]
    private var actionCompletion: AsyncResult<AdvancedCheckoutResult>?

    init(
        callbacksApi: CheckoutCallbacksFlutterApi,
        actionOnlyApi: ActionOnlyFlutterApi,
        holder: CheckoutHolder,
        events: ComponentPlatformEventHandler,
        registry: CheckoutComponentRegistry
    ) {
        self.callbacksApi = callbacksApi
        self.actionOnlyApi = actionOnlyApi
        self.holder = holder
        self.events = events
        self.registry = registry
    }

    func setupSession(
        sessionResponse: SessionResponseDTO,
        configuration: CheckoutConfigurationDTO,
        completion: @escaping (Result<CheckoutSetupResultDTO, Error>) -> Void
    ) {
        let checkoutId = UUID().uuidString
        Task { @MainActor in
            do {
                guard !holder.isActive else {
                    throw AdyenPigeonError(code: "CheckoutAlreadyActive", message: "Another checkout flow is already active.", details: nil)
                }
                _ = makePresentationDelegate(id: checkoutId)
                let checkout = try await Checkout.setup(
                    with: sessionResponse.toSessionResponse(),
                    configuration: configuration.toCheckoutConfiguration(callbacksApi: callbacksApi, checkoutId: checkoutId)
                )
                .onAction { [weak self] _, viewController in
                    self?.presentationDelegates[checkoutId]?.present(viewController)
                }
                .onBeforeSubmit { [weak self] data in
                    guard let self else { return .abort }
                    return await self.requestBeforeSubmit(checkoutId: checkoutId, data: data)
                }
                .onComplete { [weak self] result in
                    self?.sendComplete(checkoutId: checkoutId, result: result)
                }
                .onFailure { [weak self] error in
                    self?.sendFailure(checkoutId: checkoutId, error: error)
                }
                let reply = try checkout.setupResult(checkoutId: checkoutId)
                holder.store(checkout, id: checkoutId)
                completion(.success(reply))
            } catch {
                completion(.failure(asPigeonError(error)))
            }
        }
    }

    func setupAdvanced(
        paymentMethodsJson: String,
        configuration: CheckoutConfigurationDTO,
        completion: @escaping (Result<CheckoutSetupResultDTO, Error>) -> Void
    ) {
        let checkoutId = UUID().uuidString
        Task { @MainActor in
            do {
                guard !holder.isActive else {
                    throw AdyenPigeonError(code: "CheckoutAlreadyActive", message: "Another checkout flow is already active.", details: nil)
                }
                let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsJson.utf8))
                _ = makePresentationDelegate(id: checkoutId)
                let checkout = try await Checkout.setup(
                    with: paymentMethods,
                    configuration: configuration.toCheckoutConfiguration(callbacksApi: callbacksApi, checkoutId: checkoutId)
                )
                .onAction { [weak self] _, viewController in
                    self?.presentationDelegates[checkoutId]?.present(viewController)
                }
                .onSubmit { [weak self] data in
                    guard let self else { return .retry(errorMessage: "Checkout is no longer active.") }
                    return await self.requestSubmit(checkoutId: checkoutId, data: data)
                }
                .onAdditionalDetails { [weak self] data in
                    guard let self else { return .completion(resultCode: "Error") }
                    return await self.requestAdditionalDetails(checkoutId: checkoutId, data: data)
                }
                .onComplete { [weak self] result in
                    self?.sendComplete(checkoutId: checkoutId, result: result)
                }
                .onFailure { [weak self] error in
                    self?.sendFailure(checkoutId: checkoutId, error: error)
                }
                let reply = try checkout.setupResult(checkoutId: checkoutId)
                holder.store(checkout, id: checkoutId)
                completion(.success(reply))
            } catch {
                completion(.failure(asPigeonError(error)))
            }
        }
    }

    func disposeCheckout(checkoutId: String) throws {
        holder.removeCheckout(for: checkoutId)
        presentationDelegates.removeValue(forKey: checkoutId)
        dropInComponents.removeValue(forKey: checkoutId)
        registry.clear(checkoutId: checkoutId)
    }

    func clearActiveCheckout() throws {
        holder.clear()
        registry.clear()
        dropInComponents.removeAll()
        presentationDelegates.removeAll()
        actionCompletion = nil
    }

    func startDropIn(checkoutId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            guard let checkout = holder.checkout(for: checkoutId) else {
                throw AdyenPigeonError(code: "Generic", message: "Drop-in requires an active session checkout.", details: nil)
            }
            guard dropInComponents[checkoutId] == nil else {
                throw AdyenPigeonError(code: "CheckoutAlreadyActive", message: "Drop-in is already active.", details: nil)
            }
            let dropIn = try checkout.createDropIn()
            dropInComponents[checkoutId] = dropIn
            makePresentationDelegate(id: checkoutId).present(dropIn.viewController)
            completion(.success(()))
        } catch {
            completion(.failure(asPigeonError(error)))
        }
    }

    func handleAction(
        actionId: String,
        actionJson: String,
        configuration: CheckoutConfigurationDTO,
        completion: @escaping (Result<AdvancedCheckoutResultDTO, Error>) -> Void
    ) {
        guard holder.beginAction(id: actionId) else {
            completion(.failure(AdyenPigeonError(
                code: "CheckoutAlreadyActive",
                message: "Another checkout flow is already active.",
                details: nil
            )))
            return
        }
        Task { @MainActor in
            defer {
                holder.endAction(id: actionId)
                presentationDelegates[actionId]?.dismiss()
                presentationDelegates.removeValue(forKey: actionId)
            }
            do {
                let action = try JSONDecoder().decode(Action.self, from: Data(actionJson.utf8))
                _ = makePresentationDelegate(id: actionId)
                let checkout = try await Checkout.setup(
                    configuration: configuration.toCheckoutConfiguration()
                )
                let result = AsyncResult<AdvancedCheckoutResult>()
                actionCompletion = result
                _ = checkout
                    .onAction { [weak self] _, viewController in
                        self?.presentationDelegates[actionId]?.present(viewController)
                    }
                    .onAdditionalDetails { [weak self] data in
                        guard let self else { return .completion(resultCode: "Error") }
                        do {
                            return try await self.requestActionDetails(actionId: actionId, data: data)
                        } catch {
                            result.fail(error)
                            return .completion(resultCode: "Error")
                        }
                    }
                    .onComplete { value in result.succeed(value) }
                    .onFailure { error in result.fail(error) }
                holder.actionCheckout = checkout
                checkout.handle(action: action)
                let value = try await result.wait()
                completion(.success(AdvancedCheckoutResultDTO(resultCode: value.resultCode.rawValue)))
            } catch {
                completion(.failure(asPigeonError(error)))
            }
            actionCompletion = nil
        }
    }

    func enableConsoleLogging(enabled: Bool) throws {
        AdyenLogging.isEnabled = enabled
    }

    func encryptCard(
        card: UnencryptedCardDTO,
        publicKey: String,
        completion: @escaping (Result<EncryptedCardDTO, Error>) -> Void
    ) {
        do {
            let encrypted = try CardEncryptor.encrypt(card: card.toCard(), with: publicKey)
            completion(.success(encrypted.toDTO()))
        } catch {
            completion(.failure(asPigeonError(error)))
        }
    }

    func encryptBin(
        bin: String,
        publicKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        do {
            try completion(.success(CardEncryptor.encrypt(bin: bin, with: publicKey)))
        } catch {
            completion(.failure(asPigeonError(error)))
        }
    }

    func validateCardNumber(cardNumber: String, enableLuhnCheck: Bool) throws -> Bool {
        CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: enableLuhnCheck)
    }

    func validateCardExpiryDate(expiryMonth: String, expiryYear: String) throws -> Bool {
        CardValidation().validateCardExpiryDate(expiryMonth: expiryMonth, expiryYear: expiryYear)
    }

    func validateCardSecurityCode(securityCode: String, cardBrand: String?) throws -> Bool {
        CardValidation().validateCardSecurityCode(securityCode: securityCode, cardBrand: cardBrand)
    }

    func getThreeDS2SdkVersion() throws -> String {
        threeDS2SdkVersion
    }

    func handleReturn(url: URL) {
        _ = Checkout.handleReturn(url: url)
    }

    func teardown() {
        holder.clear()
        registry.clear()
        presentationDelegates.removeAll()
        dropInComponents.removeAll()
        actionCompletion = nil
    }

    private func requestBeforeSubmit(checkoutId: String, data: BeforeSubmitData) async -> BeforeSubmitResult {
        await withCheckedContinuation { continuation in
            callbacksApi.onBeforeSubmit(
                checkoutId: checkoutId,
                data: data.toDTO()
            ) { result in
                switch result {
                case let .success(value):
                    continuation.resume(returning: value.toNativeResult(original: data))
                case let .failure(error):
                    self.sendFailure(checkoutId: checkoutId, code: "CallbackFailure", message: error.localizedDescription)
                    continuation.resume(returning: .abort)
                }
            }
        }
    }

    private func requestSubmit(checkoutId: String, data: PaymentComponentData) async -> SubmitResult {
        do {
            let dataJson = try EncodablePaymentComponentData(data: data).jsonString
            return await withCheckedContinuation { continuation in
                callbacksApi.onSubmit(
                    checkoutId: checkoutId,
                    data: PaymentComponentDataDTO(dataJson: dataJson)
                ) { result in
                    switch result {
                    case let .success(value):
                        do {
                            try continuation.resume(returning: value.toNativeResult())
                        } catch {
                            continuation.resume(returning: .retry(errorMessage: error.localizedDescription))
                        }
                    case let .failure(error):
                        continuation.resume(returning: .retry(errorMessage: error.localizedDescription))
                    }
                }
            }
        } catch {
            return .retry(errorMessage: error.localizedDescription)
        }
    }

    private func requestAdditionalDetails(checkoutId: String, data: ActionComponentData) async -> AdditionalDetailsResult {
        do {
            let dataJson = try EncodableActionComponentData(data: data).jsonString
            return await withCheckedContinuation { continuation in
                callbacksApi.onAdditionalDetails(
                    checkoutId: checkoutId,
                    data: ActionComponentDataDTO(dataJson: dataJson)
                ) { result in
                    switch result {
                    case let .success(value):
                        continuation.resume(returning: .completion(resultCode: value.resultCode))
                    case let .failure(error):
                        self.sendFailure(checkoutId: checkoutId, code: "CallbackFailure", message: error.localizedDescription)
                        continuation.resume(returning: .completion(resultCode: "Error"))
                    }
                }
            }
        } catch {
            sendFailure(checkoutId: checkoutId, code: "CallbackFailure", message: error.localizedDescription)
            return .completion(resultCode: "Error")
        }
    }

    private func requestActionDetails(actionId: String, data: ActionComponentData) async throws -> AdditionalDetailsResult {
        let dataJson = try EncodableActionComponentData(data: data).jsonString
        return try await withCheckedThrowingContinuation { continuation in
            actionOnlyApi.onAdditionalDetails(
                actionId: actionId,
                data: ActionComponentDataDTO(dataJson: dataJson)
            ) { result in
                switch result {
                case let .success(value):
                    continuation.resume(returning: .completion(resultCode: value.resultCode))
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func sendComplete(checkoutId: String, result: SessionCheckoutResult) {
        presentationDelegates[checkoutId]?.dismiss()
        dropInComponents.removeValue(forKey: checkoutId)
        events.send(event: CheckoutEventDTO(
            type: .complete,
            checkoutId: checkoutId,
            resultCode: result.resultCode.rawValue,
            sessionId: result.sessionId,
            sessionResult: result.sessionResult
        ))
    }

    private func sendComplete(checkoutId: String, result: AdvancedCheckoutResult) {
        presentationDelegates[checkoutId]?.dismiss()
        dropInComponents.removeValue(forKey: checkoutId)
        events.send(event: CheckoutEventDTO(
            type: .complete,
            checkoutId: checkoutId,
            resultCode: result.resultCode.rawValue
        ))
    }

    private func sendFailure(checkoutId: String, error: CheckoutError) {
        sendFailure(checkoutId: checkoutId, code: error.code.rawValue, message: error.message)
    }

    private func sendFailure(checkoutId: String, code: String, message: String?) {
        presentationDelegates[checkoutId]?.dismiss()
        dropInComponents.removeValue(forKey: checkoutId)
        events.send(event: CheckoutEventDTO(
            type: .failure,
            checkoutId: checkoutId,
            errorCode: code,
            errorMessage: message
        ))
    }

    private func makePresentationDelegate(id: String) -> PresentationDelegateProxy {
        if let delegate = presentationDelegates[id] {
            return delegate
        }
        let delegate = PresentationDelegateProxy(viewController: rootViewController())
        presentationDelegates[id] = delegate
        return delegate
    }

    private func rootViewController() -> UIViewController? {
        UIViewController.keyWindowRoot
    }
}

// swiftlint:enable type_body_length

@MainActor
private final class PresentationDelegateProxy: NSObject {
    weak var presentingViewController: UIViewController?
    private weak var presentedViewController: UIViewController?

    init(viewController: UIViewController?) {
        self.presentingViewController = viewController
    }

    func present(_ viewController: UIViewController) {
        let presenter = presentingViewController?.topPresenter
        presentedViewController = viewController
        presenter?.present(viewController, animated: true)
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let presented = presentedViewController {
            presented.dismiss(animated: animated, completion: completion)
            presentedViewController = nil
        } else {
            completion?()
        }
    }
}

private final class AsyncResult<Value> {
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?

    func wait() async throws -> Value {
        if let result {
            return try result.get()
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func succeed(_ value: Value) {
        resolve(.success(value))
    }

    func fail(_ error: Error) {
        resolve(.failure(error))
    }

    private func resolve(_ result: Result<Value, Error>) {
        guard self.result == nil else { return }
        self.result = result
        continuation?.resume(with: result)
        continuation = nil
    }
}

private func asPigeonError(_ error: Error) -> AdyenPigeonError {
    if let error = error as? AdyenPigeonError {
        return error
    }
    if let error = error as? CheckoutError {
        return AdyenPigeonError(code: error.code.rawValue, message: error.message, details: nil)
    }
    return AdyenPigeonError(code: "Generic", message: error.localizedDescription, details: nil)
}
