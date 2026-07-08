//
//  Connectivity.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 10/4/24.
//

import Foundation
import PingOneWallet
import DIDSDK

public class Connectivity {
    
    class func checkNetworkStatus() -> Bool {
        if let networkReachability = DIDSDK.NetworkReachability() {
            PingOneWallet.logattention("Starting network status notifier: \(networkReachability.startNotifier())")
            switch networkReachability.currentNetworkStatus {
            case .available(_):
                PingOneWallet.logattention("Network status check successful - Available.")
                return true
            case .unavailable,
                 .unknown:
                fallthrough
            @unknown default:
                return false
            }
        } else {
            PingOneWallet.logerror("Failed to initialize NetworkReachability.")
            return false
        }
    }
    
}
