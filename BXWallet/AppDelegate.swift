//
//  AppDelegate.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 8/12/25.
//

import SwiftUI
import Firebase
import PingOneWallet

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()

        PingOneWalletHelper.initializeWallet()
            .onError { error in
                PingOneWallet.logerror("Error initializing SDK: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    ApplicationUiHandler().showErrorAlert(title: String(localized: "error"), message: String(localized: "wallet.initialization.error"), actionTitle: String(localized: "okay"), actionHandler: nil)
                }
                
            }
            .onResult { pingOneWalletHelper in
                let coordinator = WalletCoordinator(pingOneWalletHelper: pingOneWalletHelper)
                pingOneWalletHelper.setApplicationUiCallbackHandler(coordinator)
                pingOneWalletHelper.setCredentialPicker(DefaultCredentialPicker(applicationUiCallbackHandler: coordinator))
                WalletViewModel.shared.walletSuccessfullyInitialized(coordinator: coordinator)
                pingOneWalletHelper.processLaunchOptions(launchOptions)
            }
        
        return true
    }
}


