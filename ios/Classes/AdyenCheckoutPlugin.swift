import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {

  public static func register(with registrar: FlutterPluginRegistrar) {
      let api: CheckoutApi = CheckoutApiImpl()
      let messenger : FlutterBinaryMessenger = registrar.messenger()
      CheckoutApiSetup.setUp(binaryMessenger: messenger, api: api)
      
    let channel = FlutterMethodChannel(name: "adyen_checkout", binaryMessenger: registrar.messenger())
    let instance = AdyenCheckoutPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
