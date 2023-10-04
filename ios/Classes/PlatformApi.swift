// Autogenerated from Pigeon (v12.0.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation
#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#else
#error("Unsupported platform.")
#endif

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)"
  ]
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

enum Environment: Int {
  case test = 0
  case europe = 1
  case unitedStates = 2
  case australia = 3
  case india = 4
  case apse = 5
}

enum AddressMode: Int {
  case full = 0
  case postalCode = 1
  case none = 2
}

enum CardAuthMethod: Int {
  case panOnly = 0
  case cryptogram3DS = 1
}

enum TotalPriceStatus: Int {
  case notCurrentlyKnown = 0
  case estimated = 1
  case finalPrice = 2
}

enum GooglePayEnvironment: Int {
  case test = 0
  case production = 1
}

enum CashAppPayEnvironment: Int {
  case sandbox = 0
  case production = 1
}

enum PaymentResultEnum: Int {
  case cancelledByUser = 0
  case error = 1
  case finished = 2
}

enum PlatformCommunicationType: Int {
  case paymentComponent = 0
  case additionalDetails = 1
  case result = 2
  case deleteStoredPaymentMethod = 3
}

enum DropInResultType: Int {
  case finished = 0
  case action = 1
  case error = 2
}

enum FieldVisibility: Int {
  case show = 0
  case hide = 1
}

/// Generated class from Pigeon that represents data sent in messages.
struct SessionDTO {
  var id: String
  var sessionData: String

  static func fromList(_ list: [Any?]) -> SessionDTO? {
    let id = list[0] as! String
    let sessionData = list[1] as! String

    return SessionDTO(
      id: id,
      sessionData: sessionData
    )
  }
  func toList() -> [Any?] {
    return [
      id,
      sessionData,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct AmountDTO {
  var currency: String
  var value: Int64

  static func fromList(_ list: [Any?]) -> AmountDTO? {
    let currency = list[0] as! String
    let value = list[1] is Int64 ? list[1] as! Int64 : Int64(list[1] as! Int32)

    return AmountDTO(
      currency: currency,
      value: value
    )
  }
  func toList() -> [Any?] {
    return [
      currency,
      value,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct AnalyticsOptionsDTO {
  var enabled: Bool? = nil
  var payload: String? = nil

  static func fromList(_ list: [Any?]) -> AnalyticsOptionsDTO? {
    let enabled: Bool? = nilOrValue(list[0])
    let payload: String? = nilOrValue(list[1])

    return AnalyticsOptionsDTO(
      enabled: enabled,
      payload: payload
    )
  }
  func toList() -> [Any?] {
    return [
      enabled,
      payload,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct DropInConfigurationDTO {
  var environment: Environment
  var clientKey: String
  var countryCode: String
  var amount: AmountDTO
  var shopperLocale: String
  var cardsConfigurationDTO: CardsConfigurationDTO? = nil
  var applePayConfigurationDTO: ApplePayConfigurationDTO? = nil
  var googlePayConfigurationDTO: GooglePayConfigurationDTO? = nil
  var cashAppPayConfigurationDTO: CashAppPayConfigurationDTO? = nil
  var analyticsOptionsDTO: AnalyticsOptionsDTO? = nil
  var showPreselectedStoredPaymentMethod: Bool
  var skipListWhenSinglePaymentMethod: Bool
  var isRemoveStoredPaymentMethodEnabled: Bool

  static func fromList(_ list: [Any?]) -> DropInConfigurationDTO? {
    let environment = Environment(rawValue: list[0] as! Int)!
    let clientKey = list[1] as! String
    let countryCode = list[2] as! String
    let amount = AmountDTO.fromList(list[3] as! [Any?])!
    let shopperLocale = list[4] as! String
    var cardsConfigurationDTO: CardsConfigurationDTO? = nil
    if let cardsConfigurationDTOList: [Any?] = nilOrValue(list[5]) {
      cardsConfigurationDTO = CardsConfigurationDTO.fromList(cardsConfigurationDTOList)
    }
    var applePayConfigurationDTO: ApplePayConfigurationDTO? = nil
    if let applePayConfigurationDTOList: [Any?] = nilOrValue(list[6]) {
      applePayConfigurationDTO = ApplePayConfigurationDTO.fromList(applePayConfigurationDTOList)
    }
    var googlePayConfigurationDTO: GooglePayConfigurationDTO? = nil
    if let googlePayConfigurationDTOList: [Any?] = nilOrValue(list[7]) {
      googlePayConfigurationDTO = GooglePayConfigurationDTO.fromList(googlePayConfigurationDTOList)
    }
    var cashAppPayConfigurationDTO: CashAppPayConfigurationDTO? = nil
    if let cashAppPayConfigurationDTOList: [Any?] = nilOrValue(list[8]) {
      cashAppPayConfigurationDTO = CashAppPayConfigurationDTO.fromList(cashAppPayConfigurationDTOList)
    }
    var analyticsOptionsDTO: AnalyticsOptionsDTO? = nil
    if let analyticsOptionsDTOList: [Any?] = nilOrValue(list[9]) {
      analyticsOptionsDTO = AnalyticsOptionsDTO.fromList(analyticsOptionsDTOList)
    }
    let showPreselectedStoredPaymentMethod = list[10] as! Bool
    let skipListWhenSinglePaymentMethod = list[11] as! Bool
    let isRemoveStoredPaymentMethodEnabled = list[12] as! Bool

    return DropInConfigurationDTO(
      environment: environment,
      clientKey: clientKey,
      countryCode: countryCode,
      amount: amount,
      shopperLocale: shopperLocale,
      cardsConfigurationDTO: cardsConfigurationDTO,
      applePayConfigurationDTO: applePayConfigurationDTO,
      googlePayConfigurationDTO: googlePayConfigurationDTO,
      cashAppPayConfigurationDTO: cashAppPayConfigurationDTO,
      analyticsOptionsDTO: analyticsOptionsDTO,
      showPreselectedStoredPaymentMethod: showPreselectedStoredPaymentMethod,
      skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
      isRemoveStoredPaymentMethodEnabled: isRemoveStoredPaymentMethodEnabled
    )
  }
  func toList() -> [Any?] {
    return [
      environment.rawValue,
      clientKey,
      countryCode,
      amount.toList(),
      shopperLocale,
      cardsConfigurationDTO?.toList(),
      applePayConfigurationDTO?.toList(),
      googlePayConfigurationDTO?.toList(),
      cashAppPayConfigurationDTO?.toList(),
      analyticsOptionsDTO?.toList(),
      showPreselectedStoredPaymentMethod,
      skipListWhenSinglePaymentMethod,
      isRemoveStoredPaymentMethodEnabled,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CardsConfigurationDTO {
  var holderNameRequired: Bool
  var addressMode: AddressMode
  var showStorePaymentField: Bool
  var showCvcForStoredCard: Bool
  var showCvc: Bool
  var kcpFieldVisibility: FieldVisibility
  var socialSecurityNumberFieldVisibility: FieldVisibility
  var supportedCardTypes: [String?]

  static func fromList(_ list: [Any?]) -> CardsConfigurationDTO? {
    let holderNameRequired = list[0] as! Bool
    let addressMode = AddressMode(rawValue: list[1] as! Int)!
    let showStorePaymentField = list[2] as! Bool
    let showCvcForStoredCard = list[3] as! Bool
    let showCvc = list[4] as! Bool
    let kcpFieldVisibility = FieldVisibility(rawValue: list[5] as! Int)!
    let socialSecurityNumberFieldVisibility = FieldVisibility(rawValue: list[6] as! Int)!
    let supportedCardTypes = list[7] as! [String?]

    return CardsConfigurationDTO(
      holderNameRequired: holderNameRequired,
      addressMode: addressMode,
      showStorePaymentField: showStorePaymentField,
      showCvcForStoredCard: showCvcForStoredCard,
      showCvc: showCvc,
      kcpFieldVisibility: kcpFieldVisibility,
      socialSecurityNumberFieldVisibility: socialSecurityNumberFieldVisibility,
      supportedCardTypes: supportedCardTypes
    )
  }
  func toList() -> [Any?] {
    return [
      holderNameRequired,
      addressMode.rawValue,
      showStorePaymentField,
      showCvcForStoredCard,
      showCvc,
      kcpFieldVisibility.rawValue,
      socialSecurityNumberFieldVisibility.rawValue,
      supportedCardTypes,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct ApplePayConfigurationDTO {
  var merchantId: String
  var merchantName: String
  var allowOnboarding: Bool

  static func fromList(_ list: [Any?]) -> ApplePayConfigurationDTO? {
    let merchantId = list[0] as! String
    let merchantName = list[1] as! String
    let allowOnboarding = list[2] as! Bool

    return ApplePayConfigurationDTO(
      merchantId: merchantId,
      merchantName: merchantName,
      allowOnboarding: allowOnboarding
    )
  }
  func toList() -> [Any?] {
    return [
      merchantId,
      merchantName,
      allowOnboarding,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct GooglePayConfigurationDTO {
  var googlePayEnvironment: GooglePayEnvironment
  var merchantAccount: String? = nil
  var allowedCardNetworks: [String?]
  var allowedAuthMethods: [String?]
  var totalPriceStatus: TotalPriceStatus? = nil
  var allowPrepaidCards: Bool
  var billingAddressRequired: Bool
  var emailRequired: Bool
  var shippingAddressRequired: Bool
  var existingPaymentMethodRequired: Bool

  static func fromList(_ list: [Any?]) -> GooglePayConfigurationDTO? {
    let googlePayEnvironment = GooglePayEnvironment(rawValue: list[0] as! Int)!
    let merchantAccount: String? = nilOrValue(list[1])
    let allowedCardNetworks = list[2] as! [String?]
    let allowedAuthMethods = list[3] as! [String?]
    var totalPriceStatus: TotalPriceStatus? = nil
    let totalPriceStatusEnumVal: Int? = nilOrValue(list[4])
    if let totalPriceStatusRawValue = totalPriceStatusEnumVal {
      totalPriceStatus = TotalPriceStatus(rawValue: totalPriceStatusRawValue)!
    }
    let allowPrepaidCards = list[5] as! Bool
    let billingAddressRequired = list[6] as! Bool
    let emailRequired = list[7] as! Bool
    let shippingAddressRequired = list[8] as! Bool
    let existingPaymentMethodRequired = list[9] as! Bool

    return GooglePayConfigurationDTO(
      googlePayEnvironment: googlePayEnvironment,
      merchantAccount: merchantAccount,
      allowedCardNetworks: allowedCardNetworks,
      allowedAuthMethods: allowedAuthMethods,
      totalPriceStatus: totalPriceStatus,
      allowPrepaidCards: allowPrepaidCards,
      billingAddressRequired: billingAddressRequired,
      emailRequired: emailRequired,
      shippingAddressRequired: shippingAddressRequired,
      existingPaymentMethodRequired: existingPaymentMethodRequired
    )
  }
  func toList() -> [Any?] {
    return [
      googlePayEnvironment.rawValue,
      merchantAccount,
      allowedCardNetworks,
      allowedAuthMethods,
      totalPriceStatus?.rawValue,
      allowPrepaidCards,
      billingAddressRequired,
      emailRequired,
      shippingAddressRequired,
      existingPaymentMethodRequired,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct CashAppPayConfigurationDTO {
  var cashAppPayEnvironment: CashAppPayEnvironment
  var returnUrl: String

  static func fromList(_ list: [Any?]) -> CashAppPayConfigurationDTO? {
    let cashAppPayEnvironment = CashAppPayEnvironment(rawValue: list[0] as! Int)!
    let returnUrl = list[1] as! String

    return CashAppPayConfigurationDTO(
      cashAppPayEnvironment: cashAppPayEnvironment,
      returnUrl: returnUrl
    )
  }
  func toList() -> [Any?] {
    return [
      cashAppPayEnvironment.rawValue,
      returnUrl,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct PaymentResultDTO {
  var type: PaymentResultEnum
  var reason: String? = nil
  var result: PaymentResultModelDTO? = nil

  static func fromList(_ list: [Any?]) -> PaymentResultDTO? {
    let type = PaymentResultEnum(rawValue: list[0] as! Int)!
    let reason: String? = nilOrValue(list[1])
    var result: PaymentResultModelDTO? = nil
    if let resultList: [Any?] = nilOrValue(list[2]) {
      result = PaymentResultModelDTO.fromList(resultList)
    }

    return PaymentResultDTO(
      type: type,
      reason: reason,
      result: result
    )
  }
  func toList() -> [Any?] {
    return [
      type.rawValue,
      reason,
      result?.toList(),
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct PaymentResultModelDTO {
  var sessionId: String? = nil
  var sessionData: String? = nil
  var resultCode: String? = nil
  var order: OrderResponseDTO? = nil

  static func fromList(_ list: [Any?]) -> PaymentResultModelDTO? {
    let sessionId: String? = nilOrValue(list[0])
    let sessionData: String? = nilOrValue(list[1])
    let resultCode: String? = nilOrValue(list[2])
    var order: OrderResponseDTO? = nil
    if let orderList: [Any?] = nilOrValue(list[3]) {
      order = OrderResponseDTO.fromList(orderList)
    }

    return PaymentResultModelDTO(
      sessionId: sessionId,
      sessionData: sessionData,
      resultCode: resultCode,
      order: order
    )
  }
  func toList() -> [Any?] {
    return [
      sessionId,
      sessionData,
      resultCode,
      order?.toList(),
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct OrderResponseDTO {
  var pspReference: String
  var orderData: String
  var amount: AmountDTO? = nil
  var remainingAmount: AmountDTO? = nil

  static func fromList(_ list: [Any?]) -> OrderResponseDTO? {
    let pspReference = list[0] as! String
    let orderData = list[1] as! String
    var amount: AmountDTO? = nil
    if let amountList: [Any?] = nilOrValue(list[2]) {
      amount = AmountDTO.fromList(amountList)
    }
    var remainingAmount: AmountDTO? = nil
    if let remainingAmountList: [Any?] = nilOrValue(list[3]) {
      remainingAmount = AmountDTO.fromList(remainingAmountList)
    }

    return OrderResponseDTO(
      pspReference: pspReference,
      orderData: orderData,
      amount: amount,
      remainingAmount: remainingAmount
    )
  }
  func toList() -> [Any?] {
    return [
      pspReference,
      orderData,
      amount?.toList(),
      remainingAmount?.toList(),
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct PlatformCommunicationModel {
  var type: PlatformCommunicationType
  var data: String? = nil
  var paymentResult: PaymentResultDTO? = nil

  static func fromList(_ list: [Any?]) -> PlatformCommunicationModel? {
    let type = PlatformCommunicationType(rawValue: list[0] as! Int)!
    let data: String? = nilOrValue(list[1])
    var paymentResult: PaymentResultDTO? = nil
    if let paymentResultList: [Any?] = nilOrValue(list[2]) {
      paymentResult = PaymentResultDTO.fromList(paymentResultList)
    }

    return PlatformCommunicationModel(
      type: type,
      data: data,
      paymentResult: paymentResult
    )
  }
  func toList() -> [Any?] {
    return [
      type.rawValue,
      data,
      paymentResult?.toList(),
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct DropInResultDTO {
  var dropInResultType: DropInResultType
  var result: String? = nil
  var actionResponse: [String?: Any?]? = nil
  var error: DropInErrorDTO? = nil

  static func fromList(_ list: [Any?]) -> DropInResultDTO? {
    let dropInResultType = DropInResultType(rawValue: list[0] as! Int)!
    let result: String? = nilOrValue(list[1])
    let actionResponse: [String?: Any?]? = nilOrValue(list[2])
    var error: DropInErrorDTO? = nil
    if let errorList: [Any?] = nilOrValue(list[3]) {
      error = DropInErrorDTO.fromList(errorList)
    }

    return DropInResultDTO(
      dropInResultType: dropInResultType,
      result: result,
      actionResponse: actionResponse,
      error: error
    )
  }
  func toList() -> [Any?] {
    return [
      dropInResultType.rawValue,
      result,
      actionResponse,
      error?.toList(),
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct DropInErrorDTO {
  var errorMessage: String? = nil
  var reason: String? = nil
  var dismissDropIn: Bool? = nil

  static func fromList(_ list: [Any?]) -> DropInErrorDTO? {
    let errorMessage: String? = nilOrValue(list[0])
    let reason: String? = nilOrValue(list[1])
    let dismissDropIn: Bool? = nilOrValue(list[2])

    return DropInErrorDTO(
      errorMessage: errorMessage,
      reason: reason,
      dismissDropIn: dismissDropIn
    )
  }
  func toList() -> [Any?] {
    return [
      errorMessage,
      reason,
      dismissDropIn,
    ]
  }
}

/// Generated class from Pigeon that represents data sent in messages.
struct DeletedStoredPaymentMethodResultDTO {
  var storedPaymentMethodId: String
  var isSuccessfullyRemoved: Bool

  static func fromList(_ list: [Any?]) -> DeletedStoredPaymentMethodResultDTO? {
    let storedPaymentMethodId = list[0] as! String
    let isSuccessfullyRemoved = list[1] as! Bool

    return DeletedStoredPaymentMethodResultDTO(
      storedPaymentMethodId: storedPaymentMethodId,
      isSuccessfullyRemoved: isSuccessfullyRemoved
    )
  }
  func toList() -> [Any?] {
    return [
      storedPaymentMethodId,
      isSuccessfullyRemoved,
    ]
  }
}

private class CheckoutPlatformInterfaceCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
      case 128:
        return AmountDTO.fromList(self.readValue() as! [Any?])
      case 129:
        return AnalyticsOptionsDTO.fromList(self.readValue() as! [Any?])
      case 130:
        return ApplePayConfigurationDTO.fromList(self.readValue() as! [Any?])
      case 131:
        return CardsConfigurationDTO.fromList(self.readValue() as! [Any?])
      case 132:
        return CashAppPayConfigurationDTO.fromList(self.readValue() as! [Any?])
      case 133:
        return DeletedStoredPaymentMethodResultDTO.fromList(self.readValue() as! [Any?])
      case 134:
        return DropInConfigurationDTO.fromList(self.readValue() as! [Any?])
      case 135:
        return DropInErrorDTO.fromList(self.readValue() as! [Any?])
      case 136:
        return DropInResultDTO.fromList(self.readValue() as! [Any?])
      case 137:
        return GooglePayConfigurationDTO.fromList(self.readValue() as! [Any?])
      case 138:
        return SessionDTO.fromList(self.readValue() as! [Any?])
      default:
        return super.readValue(ofType: type)
    }
  }
}

private class CheckoutPlatformInterfaceCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? AmountDTO {
      super.writeByte(128)
      super.writeValue(value.toList())
    } else if let value = value as? AnalyticsOptionsDTO {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? ApplePayConfigurationDTO {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else if let value = value as? CardsConfigurationDTO {
      super.writeByte(131)
      super.writeValue(value.toList())
    } else if let value = value as? CashAppPayConfigurationDTO {
      super.writeByte(132)
      super.writeValue(value.toList())
    } else if let value = value as? DeletedStoredPaymentMethodResultDTO {
      super.writeByte(133)
      super.writeValue(value.toList())
    } else if let value = value as? DropInConfigurationDTO {
      super.writeByte(134)
      super.writeValue(value.toList())
    } else if let value = value as? DropInErrorDTO {
      super.writeByte(135)
      super.writeValue(value.toList())
    } else if let value = value as? DropInResultDTO {
      super.writeByte(136)
      super.writeValue(value.toList())
    } else if let value = value as? GooglePayConfigurationDTO {
      super.writeByte(137)
      super.writeValue(value.toList())
    } else if let value = value as? SessionDTO {
      super.writeByte(138)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class CheckoutPlatformInterfaceCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return CheckoutPlatformInterfaceCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return CheckoutPlatformInterfaceCodecWriter(data: data)
  }
}

class CheckoutPlatformInterfaceCodec: FlutterStandardMessageCodec {
  static let shared = CheckoutPlatformInterfaceCodec(readerWriter: CheckoutPlatformInterfaceCodecReaderWriter())
}

/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol CheckoutPlatformInterface {
  func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void)
  func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void)
  func startDropInSessionPayment(dropInConfigurationDTO: DropInConfigurationDTO, session: SessionDTO) throws
  func startDropInAdvancedFlowPayment(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) throws
  func onPaymentsResult(paymentsResult: DropInResultDTO) throws
  func onPaymentsDetailsResult(paymentsDetailsResult: DropInResultDTO) throws
  func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) throws
  func setupLogger(loggingEnabled: Bool) throws
  func cleanUpDropIn() throws
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class CheckoutPlatformInterfaceSetup {
  /// The codec used by CheckoutPlatformInterface.
  static var codec: FlutterStandardMessageCodec { CheckoutPlatformInterfaceCodec.shared }
  /// Sets up an instance of `CheckoutPlatformInterface` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: CheckoutPlatformInterface?) {
    let getPlatformVersionChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.getPlatformVersion", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getPlatformVersionChannel.setMessageHandler { _, reply in
        api.getPlatformVersion() { result in
          switch result {
            case .success(let res):
              reply(wrapResult(res))
            case .failure(let error):
              reply(wrapError(error))
          }
        }
      }
    } else {
      getPlatformVersionChannel.setMessageHandler(nil)
    }
    let getReturnUrlChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.getReturnUrl", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getReturnUrlChannel.setMessageHandler { _, reply in
        api.getReturnUrl() { result in
          switch result {
            case .success(let res):
              reply(wrapResult(res))
            case .failure(let error):
              reply(wrapError(error))
          }
        }
      }
    } else {
      getReturnUrlChannel.setMessageHandler(nil)
    }
    let startDropInSessionPaymentChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.startDropInSessionPayment", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      startDropInSessionPaymentChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let dropInConfigurationDTOArg = args[0] as! DropInConfigurationDTO
        let sessionArg = args[1] as! SessionDTO
        do {
          try api.startDropInSessionPayment(dropInConfigurationDTO: dropInConfigurationDTOArg, session: sessionArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      startDropInSessionPaymentChannel.setMessageHandler(nil)
    }
    let startDropInAdvancedFlowPaymentChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.startDropInAdvancedFlowPayment", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      startDropInAdvancedFlowPaymentChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let dropInConfigurationDTOArg = args[0] as! DropInConfigurationDTO
        let paymentMethodsResponseArg = args[1] as! String
        do {
          try api.startDropInAdvancedFlowPayment(dropInConfigurationDTO: dropInConfigurationDTOArg, paymentMethodsResponse: paymentMethodsResponseArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      startDropInAdvancedFlowPaymentChannel.setMessageHandler(nil)
    }
    let onPaymentsResultChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.onPaymentsResult", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      onPaymentsResultChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let paymentsResultArg = args[0] as! DropInResultDTO
        do {
          try api.onPaymentsResult(paymentsResult: paymentsResultArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      onPaymentsResultChannel.setMessageHandler(nil)
    }
    let onPaymentsDetailsResultChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.onPaymentsDetailsResult", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      onPaymentsDetailsResultChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let paymentsDetailsResultArg = args[0] as! DropInResultDTO
        do {
          try api.onPaymentsDetailsResult(paymentsDetailsResult: paymentsDetailsResultArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      onPaymentsDetailsResultChannel.setMessageHandler(nil)
    }
    let onDeleteStoredPaymentMethodResultChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.onDeleteStoredPaymentMethodResult", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      onDeleteStoredPaymentMethodResultChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let deleteStoredPaymentMethodResultDTOArg = args[0] as! DeletedStoredPaymentMethodResultDTO
        do {
          try api.onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: deleteStoredPaymentMethodResultDTOArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      onDeleteStoredPaymentMethodResultChannel.setMessageHandler(nil)
    }
    let setupLoggerChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.setupLogger", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      setupLoggerChannel.setMessageHandler { message, reply in
        let args = message as! [Any?]
        let loggingEnabledArg = args[0] as! Bool
        do {
          try api.setupLogger(loggingEnabled: loggingEnabledArg)
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      setupLoggerChannel.setMessageHandler(nil)
    }
    let cleanUpDropInChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutPlatformInterface.cleanUpDropIn", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      cleanUpDropInChannel.setMessageHandler { _, reply in
        do {
          try api.cleanUpDropIn()
          reply(wrapResult(nil))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      cleanUpDropInChannel.setMessageHandler(nil)
    }
  }
}
private class CheckoutFlutterApiCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
      case 128:
        return AmountDTO.fromList(self.readValue() as! [Any?])
      case 129:
        return OrderResponseDTO.fromList(self.readValue() as! [Any?])
      case 130:
        return PaymentResultDTO.fromList(self.readValue() as! [Any?])
      case 131:
        return PaymentResultModelDTO.fromList(self.readValue() as! [Any?])
      case 132:
        return PlatformCommunicationModel.fromList(self.readValue() as! [Any?])
      default:
        return super.readValue(ofType: type)
    }
  }
}

private class CheckoutFlutterApiCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? AmountDTO {
      super.writeByte(128)
      super.writeValue(value.toList())
    } else if let value = value as? OrderResponseDTO {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else if let value = value as? PaymentResultDTO {
      super.writeByte(130)
      super.writeValue(value.toList())
    } else if let value = value as? PaymentResultModelDTO {
      super.writeByte(131)
      super.writeValue(value.toList())
    } else if let value = value as? PlatformCommunicationModel {
      super.writeByte(132)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class CheckoutFlutterApiCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return CheckoutFlutterApiCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return CheckoutFlutterApiCodecWriter(data: data)
  }
}

class CheckoutFlutterApiCodec: FlutterStandardMessageCodec {
  static let shared = CheckoutFlutterApiCodec(readerWriter: CheckoutFlutterApiCodecReaderWriter())
}

/// Generated class from Pigeon that represents Flutter messages that can be called from Swift.
class CheckoutFlutterApi {
  private let binaryMessenger: FlutterBinaryMessenger
  init(binaryMessenger: FlutterBinaryMessenger){
    self.binaryMessenger = binaryMessenger
  }
  var codec: FlutterStandardMessageCodec {
    return CheckoutFlutterApiCodec.shared
  }
  func onDropInSessionPlatformCommunication(platformCommunicationModel platformCommunicationModelArg: PlatformCommunicationModel, completion: @escaping (Result<Void, FlutterError>) -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutFlutterApi.onDropInSessionPlatformCommunication", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([platformCommunicationModelArg] as [Any?]) { _ in
      completion(.success(Void()))
    }
  }
  func onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel platformCommunicationModelArg: PlatformCommunicationModel, completion: @escaping (Result<Void, FlutterError>) -> Void) {
    let channel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.adyen_checkout.CheckoutFlutterApi.onDropInAdvancedFlowPlatformCommunication", binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([platformCommunicationModelArg] as [Any?]) { _ in
      completion(.success(Void()))
    }
  }
}
