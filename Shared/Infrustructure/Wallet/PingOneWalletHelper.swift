//
//  PingOneWalletHelper.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 10/2/24.
//

import UIKit
import Foundation
import PingOneWallet
import DIDSDK

public class PingOneWalletHelper {
    
    static func initializeWallet() -> DIDSDK.CompletionHandler<PingOneWalletHelper> {
        let completionHandler = DIDSDK.CompletionHandler<PingOneWalletHelper>()
        
        let clientBuilder = PingOneWalletClient.Builder(forRegion: PingOneRegion.NA) // Defaulting to initializing for NA
        clientBuilder.build()
            .onError { error in
                completionHandler.setError(error)
            }
            .onResult { client in
                let helper = PingOneWalletHelper(client)
                completionHandler.setResult(helper)
            }
        
        return completionHandler
    }
        
    static let TOAST_DURATION: TimeInterval = 2.0
    static let LaunchOptionsUserActivityKey: String = "UIApplicationLaunchOptionsUserActivityKey"
    
    private let pingoneWalletClient: PingOneWalletClient!
    private var applicationUiCallbackHandler: ApplicationUiCallbackHandler?
    private var credentialPicker: CredentialPicker?
    
    /// Set this to true if push notifications are not configured in your app
    public var enablePolling: Bool = true
    
    init(_ pingoneWalletClient: PingOneWalletClient) {
        self.pingoneWalletClient = pingoneWalletClient
        self.pingoneWalletClient.registerCallbackHandler(self)
        
        if (self.enablePolling) {
            self.pollForMessages()
        }
    }
    
    
    /// Returns boolean indicating if Wallet SDK should poll for messages
    /// - Returns: Boolean
    public func isPollingEnabled() -> Bool {
        return self.enablePolling
    }
    
    /// Call this method to start polling for new messages sent to the wallet. Use this method only if you are not using push notifications.
    public func pollForMessages() {
        self.pingoneWalletClient.pollForMessages()
    }
    
    /// Call this method to stop polling for messages sent to the wallet.
    public func stopPolling() {
        self.pingoneWalletClient.stopPolling()
    }
    
    /// Set optional ApplicationUiCallbackHandler to handle UI notifications/Alerts etc. See protocol ApplicationUiCallbackHandler for more details.
    /// - Parameter applicationUiCallbackHandler: Implementation of protocol ApplicationUiCallbackHandler
    public func setApplicationUiCallbackHandler(_ applicationUiCallbackHandler: ApplicationUiCallbackHandler) {
        self.applicationUiCallbackHandler = applicationUiCallbackHandler
    }
    
    /// Set optional CredentialPicker implementation to handle credential selection when multiple credentials of same type are present in the wallet matching the criteria in the presentation request.
    /// - Parameter credentialPicker: Implementation of protocol CredentialPicker
    public func setCredentialPicker(_ credentialPicker: CredentialPicker) {
        self.credentialPicker = credentialPicker
    }
    
    /// Set the push token for the device to be able to receive push notifications.
    /// - Parameter pushToken: Push Token
    public func updatePushToken(_ pushToken: Data) {
        self.pingoneWalletClient.updatePushTokens(pushToken)
    }
    
    /// Call this method to handle the cases where app is opened by clocking on a URL or push notification.
    /// - Parameter launchOptions: LaunchOptions
    func processLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let userActivityDict = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [String: Any],
           let userActivity = userActivityDict[PingOneWalletHelper.LaunchOptionsUserActivityKey] as? NSUserActivity,
           let appOpenUrl = userActivity.webpageURL?.absoluteString {
            self.processPingOneRequest(appOpenUrl)
        } else if let dict = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            self.processPingOneNotification(dict)
        }
    }
    
    /// Call this method to process PingOne Credentials QR codes and Universal links.
    /// - Parameter qrContent: Content of the scanned QR code or Universal link used to open the app
    func processPingOneRequest(_ qrContent: String) {
        self.pingoneWalletClient.processPingOneRequest(qrContent)
    }
    
    /// Call this method to process the notification received by the app.
    /// - Parameter userInfo: userInfo dictionary in the notification payload
    func processPingOneNotification(_ userInfo: [AnyHashable: Any]?) {
        if (self.pingoneWalletClient.processNotification(userInfo)) {
            PingOneWallet.logattention("Processing notification...")
        } else {
            // Mark: Handle App notification here
            PingOneWallet.logattention("Handle App notification here...")
        }
    }
    
    /// Call this method to check if wallet has received any new messages in the mailbox. This method can be used to check for messages on user action or if push notifications are not available.
    public func checkForMessages() {
        self.pingoneWalletClient.checkForMessages()
    }
    
    /// Call this method when a credential is deleted from the Wallet. Reporting this action will help admins view accurate stats on their dashboards in future.
    /// - Parameter credential: Deleted credential
    public func reportCredentialDeletion(_ credential: Claim) {
        self.pingoneWalletClient.reportCredentialDeletion(claim: credential)
    }
    
    /// This method returns the data repository used by the wallet for storing ApplicationInstances and Credentials. See DataRepository for more details.
    /// - Returns: DataRepositoiry used by Wallet instance
    public func getDataRepository() -> DataRepository {
        return self.pingoneWalletClient.getDataRepository()
    }
    
    public func deleteCredential(credential: Claim, credentialDescription: String, onDelete: @escaping (Bool) -> Void) {
        self.askUserPermission(title: "Delete Credential", message: "Please confirm you wish to delete the credential for \(credentialDescription).") { userConfirmedAction in
            if (userConfirmedAction) {
                self.getDataRepository().deleteCredential(forId: credential.getId())
                self.pingoneWalletClient.reportCredentialDeletion(claim: credential)
            }
            
            onDelete(userConfirmedAction)
        }
    }
    
}

/// Extension to implement WalletCallbackHandler
extension PingOneWalletHelper: WalletCallbackHandler {
    
    /// Handle the newly issued credential.
    /// - Parameters:
    ///   - issuer: ApplicationInstanceID of the credential issuer
    ///   - message: Optional string message
    ///   - challenge: Optional challenge
    ///   - claim: Issued credential
    ///   - errors: List of any errors while processing/verifying the credential
    /// - Returns: True if the user has accepted the credential, False if the user has rejected the credential
    public func handleCredentialIssuance(issuer: String, message: String?, challenge: Challenge?, claim: Claim, errors: [PingOneWallet.WalletException]) -> Bool {
        PingOneWallet.logattention("Credential received: Issuer: \(issuer), message: \(message ?? "none")")
        self.notifyUser(message: "Received a new credential", style: .success)
        EventObserverUtils.broadcastCredentialsUpdatedNotification(delayBy: 1)
        return true
    }
    
    /// Handle the revocation of a credential.
    /// - Parameters:
    ///   - issuer: ApplicationInstanceID of the credential issuer
    ///   - message: Optional string message
    ///   - challenge: Optional challenge
    ///   - claimReference: ClaimReference for the revoked credential
    ///   - errors: List of any errors that occurred while revoking the credential
    /// - Returns: True if the user has accepted the credential revocation, False if the user has rejected the credential revocation
    public func handleCredentialRevocation(issuer: String, message: String?, challenge: Challenge?, claimReference: ClaimReference, errors: [PingOneWallet.WalletException]) -> Bool {
        PingOneWallet.logattention("Credential revoked: Issuer: \(issuer), message: \(message ?? "none")")
        self.notifyUser(message: "Credential Revoked")
        self.pingoneWalletClient.getDataRepository().deleteCredential(forId: claimReference.getId())
        EventObserverUtils.broadcastCredentialsUpdatedNotification(delayBy: 1)
        return true
    }
    
    /// This callback is triggered when another wallet shares a credential with the current application instance.
    /// - Parameters:
    ///   - sender: ApplicationInstanceID of the sender
    ///   - message: Optional string message
    ///   - challenge: Optional challenge
    ///   - claim: Shared credential
    ///   - errors: List of any errors that occurred while verifying the shared credential
    public func handleCredentialPresentation(sender: String, message: String?, challenge: Challenge?, claim: [Share], errors: [PingOneWallet.WalletException]) {
        //MARK: handle peer to peer Credential Presentation using native protocols
    }
    
    /// This callback is triggered when a credential is requested from the current wallet using supported protocols.
    /// - Parameter presentationRequest: PresentationRequest object for requesting Credentials from Wallet
    public func handleCredentialRequest(_ presentationRequest: PresentationRequest) {
        if (presentationRequest.isPairingRequest()) {
            self.handlePairingRequest(presentationRequest)
            return
        }
        
        let credentialMatcherResults = self.pingoneWalletClient.findMatchingCredentialsForRequest(presentationRequest).getResult()
        let matchingCredentials = credentialMatcherResults.filter { !$0.claims.isEmpty }
        
        guard !matchingCredentials.isEmpty else {
            self.showError(title: "No matching credentials", message: "Cannot find any credentials in your wallet matching the criteria in the request.")
            return
        }
        
        let message: String = matchingCredentials.count == credentialMatcherResults.count ? "Please confirm to present the requested credentials from your wallet." : "Your wallet does not have all the requested credentials. Would you like to share partial information?"
        let title: String = matchingCredentials.count == credentialMatcherResults.count ? "Share Information" : "Missing Credentials"
        
        self.askUserPermission(title: title , message: message) { isPositiveAction in
            if (isPositiveAction) {
                self.selectCredential(presentationRequest, credentialMatcherResults: credentialMatcherResults)
            } else {
                self.notifyUser(message: "Presentation canceled", style: .warning)
            }
        }
    }
    
    private func selectCredential(_ presentationRequest: PresentationRequest, credentialMatcherResults: [CredentialMatcherResult]) {
        self.credentialPicker?.selectCredentialFor(presentationRequest: presentationRequest, credentialMatcherResults: credentialMatcherResults, onResult: { result in
            guard let result = result, !result.isEmpty() else {
                self.notifyUser(message: "Presentation canceled", style: .warning)
                return
            }
            
            self.shareCredentialPresentation(result)
        })
    }
    
    /// Callback returns different events while using Wallet, including errors
    /// Backward compatibility - Call super.handleEvent() if you're still using `handleError` callback to manage exceptions.
    /// - Parameter event: WalletEvent
    public func handleEvent(_ event: WalletEvent) {
        switch event {
        case let event as WalletPairingEvent:
            self.handlePairingEvent(event)
        case let event as WalletCredentialEvent:
            self.handleCredentialEvent(event)
        case let event as WalletError:
            self.handleErrorEvent(event)
        default:
            PingOneWallet.logattention("Received unknown event. \(event.getType())")
        }
    }
    
}

/// Extension to manage UI notifications, alerts etc, override implementation to change default behavior
extension PingOneWalletHelper {
    
    private func handlePairingEvent(_ event: WalletPairingEvent) {
        switch event.getPairingEventType() {
        case .PAIRING_REQUEST:
            self.handlePairingRequest(event.getPairingRequest())
        case .PAIRING_RESPONSE:
            PingOneWallet.logattention("Wallet pairing success: \(String(describing: event.isSuccess())) - error: \(event.getError()?.localizedDescription ?? "None")")
            if let isSuccess = event.isSuccess() {
                GoogleAnalytics.userCompletedAction(actionName: "wallet_paired", actionSuccesful: isSuccess)
                self.notifyUser(message: isSuccess ? "Wallet paired successfully" : "Wallet pairing failed", style: isSuccess ? .success : .error)
            }
        @unknown default:
            fatalError("Unhandled Pairing Event")
        }
    }
    
    private func handlePairingRequest(_ pairingRequest: PairingRequest) {
        self.askUserPermission(title: "Pair Wallet", message: "Please confirm to pair your wallet to receive a credential.") { isPositiveAction in
            guard (isPositiveAction) else {
                GoogleAnalytics.userCompletedAction(actionName: "cancelled_pairing")
                PingOneWallet.logattention("Pairing canceled by user")
                EventObserverUtils.broadcastUserCancelledPairing()
                return
            }
            self.pingoneWalletClient.pairWallet(for: pairingRequest)
                .onResult({ _ in
                    self.notifyUser(message: "Pairing wallet...")
                })
                .onError { err in
                    PingOneWallet.logerror("Wallet pairing failed: \(err.localizedDescription)")
                    self.notifyUser(message: "Wallet pairing failed", style: .error)
                }
        }
    }
    
    private func handlePairingRequest(_ presentationRequest: PresentationRequest) {
        guard let pairingRequest = presentationRequest.getPairingRequest() else {
            PingOneWallet.logerror("Wallet pairing failed: Invalid request for pairing")
            self.notifyUser(message: "Wallet pairing failed", style: .error)
            return
        }
        self.handlePairingRequest(pairingRequest)
    }
    
    private func shareCredentialPresentation(_ credentialPresentation: CredentialsPresentation) {
        self.presentCredential(credentialPresentation)
    }
    
    private func presentCredential(_ credentialPresentation: CredentialsPresentation) {
        self.pingoneWalletClient.presentCredentials(credentialPresentation)
            .onResult { result in
                switch result.getPresentationStatus() {
                case .success:
                    self.notifyUser(message: "Information sent successfully", style: .success)
                    GoogleAnalytics.userCompletedAction(actionName: "verified_credential")
                case .failure:
                    PingOneWallet.logerror("Error sharing information: \(result.getDetails()?.debugDescription ?? "None")")
                    self.notifyUser(message: "Failed to present credential", style: .error)
                    GoogleAnalytics.userCompletedAction(actionName: "verified_credential", actionSuccesful: false)
                case .requiresAction(let action):
                    self.handlePresentationAction(action)
                @unknown default:
                    fatalError("Unhandled presentation status")
                }
            }
            .onError { err in
                PingOneWallet.logerror("Error sharing information: \(err.localizedDescription)")
                self.notifyUser(message: "Failed to present credential")
            }
    }
    
    private func handlePresentationAction(_ action: PresentationAction) {
        switch action {
        case .openUri(let redirectUri):
            self.applicationUiCallbackHandler?.openUrl(url: redirectUri, onComplete: { result, message in
                PingOneWallet.logattention("Opening URL: \(redirectUri) - result: \(result) - message: \(message)")
                self.notifyUser(message: message)
            })
        @unknown default:
            fatalError("Unhandled presentation action")
        }
    }
    
    private func handleErrorEvent(_ errorEvent: WalletError) {
        switch errorEvent.getError() {
        case .cannotProcessUrl(let url, let debugDescription):
            PingOneWallet.logerror("Failed to process url: \(url) - \(debugDescription ?? "None")")
            self.notifyUser(message: "Failed to process request", style: .error)
        default:
            PingOneWallet.logerror("Error in wallet callback handler: \(errorEvent.getError().localizedDescription)")
        }
    }

    private func handleCredentialEvent(_ event: WalletCredentialEvent) {
        switch event.getCredentialEvent() {
        case .CREDENTIAL_UPDATED:
            self.handleCredentialUpdate(event.getAction(), referenceCredentialId: event.getReferenceCredentialId())
        @unknown default:
            fatalError("Unhandled credential event")
        }
    }
    
    private func handleCredentialUpdate(_ action: CredentialAction, referenceCredentialId: String) {
        switch action {
        case .DELETE:
            self.pingoneWalletClient.getDataRepository().deleteCredential(forId: referenceCredentialId)
        @unknown default:
            fatalError("Unhandled credential updated=")
        }
    }
    
}

// Mark: ApplicationUiCallbackHandler methods

extension PingOneWalletHelper {
    
    private func notifyUser(message: String, style: ToastStyle = .info) {
        PingOneWallet.logattention(message)
        ToastPresenter.show(style: style, toast: message)
    }
    
    private func askUserPermission(title: String, message: String, actionHandler: @escaping (Bool) -> Void, positiveActionTitle: String = String(localized: "confirm"), cancelActionTitle: String = String(localized: "cancel")) {
        ConfirmationViewModel.shared.presentUserConfirmation(title: title, message: message, image: "wallet.pass", completionHandler: actionHandler)
    }
    
    private func showError(title: String, message: String) {
        PingOneWallet.logerror("\(title): \(message)")
        self.applicationUiCallbackHandler?.showErrorAlert(title: title, message: message, actionTitle: String(localized: "okay"), actionHandler: nil)
    }
    
}
