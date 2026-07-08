//
//  QRScannerViewModel.swift
//  BXMobileApps-iOS
//

import Foundation

class QRScannerViewModel: ObservableObject {
    @Published var scanResult: String? = nil
    @Published var loadingCamera: Bool = false

    /// Localization key shown while the camera session is starting.
    let loadingMessageKey: String

    /// Localization key shown as the scanning instruction overlay.
    let instructionMessageKey: String

    /// Called on the main thread whenever a QR code is successfully scanned.
    var onScanResult: ((String) -> Void)?

    init(
        loadingMessageKey: String = "wallet.camera.loading",
        instructionMessageKey: String = "wallet.camera.message",
        onScanResult: ((String) -> Void)? = nil
    ) {
        self.loadingMessageKey = loadingMessageKey
        self.instructionMessageKey = instructionMessageKey
        self.onScanResult = onScanResult
    }

    /// Called by QRScannerView when a non-nil result arrives.
    func handleScanResult(_ result: String) {
        onScanResult?(result)
    }
}
