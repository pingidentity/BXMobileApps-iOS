//
//  WalletViewModel.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 10/2/24.
//

import Foundation
import DIDSDK
import PingOneWallet

class WalletViewModel: ObservableObject {
    static let shared = WalletViewModel()
    
    @Published var presentQrScanner = false

    let qrScannerModel: QRScannerViewModel

    @Published var walletInitialized = false
    @Published var pairing = false
    @Published var credentials: [Credential] = []
    
    @Published var matchingCredentials: [Credential] = []
    @Published var requestedKeys: [String] = []
    @Published var optionalKeySelection: [String] = []
    @Published var presentCredentialPicker = false
    
    var coordinator: WalletCoordinator? = nil
    private var eventObserver: EventObserver!

    init() {
        qrScannerModel = QRScannerViewModel()
        setupQRScannerCallback()
    }

    private func setupQRScannerCallback() {
        qrScannerModel.onScanResult = { [weak self] _ in
            self?.processQrCode(false)
        }
    }

    func walletSuccessfullyInitialized(coordinator: WalletCoordinator) {
        DispatchQueue.main.async {
            self.walletInitialized = true
        }
        
        self.coordinator = coordinator
        
        refreshCredentials()
        observeAppOpenUrl()
        observeCredentialUpdates()
        observeUserCancelledPairingRequest()
    }
    
    func processQrCode(_ isPairing: Bool) {
        presentQrScanner = false
        
        guard let scanResult = qrScannerModel.scanResult else {
            print("scanResult is nil, nothing to process")
            return
        }
        
        if let scanResultUrl = URL(string: scanResult) {
            if scanResultUrl.lastPathComponent == "verify" {
                guard let rootViewController = UIUtilities.getRootViewController() else {
                    print("rootViewController was null, cannot launch verify")
                    return
                }
                
                PingOneVerifyHelper.initialize(with: scanResult, rootViewController: rootViewController) { helper, error  in
                    if let error {
                        print(error.localizedDescription!)
                        ToastPresenter.show(style: .error, toast: String(localized: "verify.launch_error"))
                        return
                    }
                    
                    helper?.start()
                }
            } else {
                pairing = isPairing
                coordinator?.processPairingUrl(qrContent: scanResult)
            }
        }
        
        qrScannerModel.scanResult = nil
    }
    
    func refreshCredentials() {
        if coordinator != nil {
            DispatchQueue.main.async {
                let claims = self.coordinator!.pingOneWalletHelper.getDataRepository().getAllCredentials()
                self.credentials = claims.map { Credential(claim: $0) }
                if self.credentials.count > 0 {
                    self.pairing = false
                }
            }
        }
    }
    
    func observeUserCancelledPairingRequest() {
        self.getEventObserver().observeUserCancelledPairing {
            self.pairing = false
        }
    }
    
    func observeCredentialUpdates() {
        self.getEventObserver().observeCredentialUpdates {
            self.refreshCredentials()
        }
    }
    
    func observeAppOpenUrl() {
        self.getEventObserver().observeAppOpenUrl { [self] url in
            if url.contains("/wallet") {
                guard let coordinator else {
                    print("Wallet not yet initialized, can't pair wallet")
                    return
                }
                
                pairing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    coordinator.processPairingUrl(qrContent: url)
                }
            }
        }
    }
    
    func presentCredentialPicker(matchingClaims: [Claim], requestedKeys: [String]) {
        self.matchingCredentials = matchingClaims.map { Credential(claim: $0) }
        self.requestedKeys = requestedKeys
        self.optionalKeySelection = []
        self.presentCredentialPicker = true
    }
    
    func credentialSelected(credential: Credential) {
        if coordinator != nil {
            coordinator!.credentialSelected(claim: credential.rawClaim, selectedKeys: self.requestedKeys + self.optionalKeySelection)
        }
        
        DispatchQueue.main.async {
            self.presentCredentialPicker = false
            self.matchingCredentials = []
            self.requestedKeys = []
            self.optionalKeySelection = []
        }
    }
    
    func deleteCredential(credential: Credential, credentialDescription: String, afterDelete: ((Bool) -> Void)? = nil) {
        guard let coordinator else {
            print("Coordinator is nil")
            return
        }
        
        coordinator.pingOneWalletHelper.deleteCredential(credential: credential.rawClaim, credentialDescription: credentialDescription) { deleted in
            DispatchQueue.main.async {
                self.refreshCredentials()
                
                if let afterDelete {
                    afterDelete(deleted)
                }
            }
        }
    }
    
    private func getEventObserver() -> EventObserver {
        if self.eventObserver == nil {
            self.eventObserver = EventObserver()
        }
        return self.eventObserver
    }

}

struct Credential: Identifiable {
    let id: UUID
    let rawClaim: Claim
    let claimValues: [String : String]
    
    init(claim: Claim) {
        self.id = UUID()
        self.rawClaim = claim
        self.claimValues = claim.getData()
            .filter({ $0.key != ClaimKeys.cardImage })
    }
    
    func getClaimValue(_ key: String, formatDate: Bool = false) -> String {
        guard let claimValue = claimValues[key] else {
            return "Attribute '\(key)' not found"
        }
        
        return formatDate ? DateUtils.getFormattedDateFromClaimValue(date: claimValue) : claimValue
    }
}
