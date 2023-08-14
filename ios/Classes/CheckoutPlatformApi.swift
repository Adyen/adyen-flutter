//
//  CheckoutApi.swift
//  adyen_checkout
//
//  Created by Robert Schulze Dieckhoff on 07/08/2023.
//

import Foundation

class CheckoutPlatformApi : CheckoutPlatformInterface {
  
    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startPayment(sessionModel: SessionModel, dropInConfiguration: DropInConfigurationModel, completion: @escaping (Result<Void, Error>) -> Void) {
    }
    
    func getReturnUrl() -> String {
        return "";
    }
    
}
