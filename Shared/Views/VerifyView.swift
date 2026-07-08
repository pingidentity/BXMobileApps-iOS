//
//  VerifyView.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 12/13/24.
//

import SwiftUI
import PingOneVerify

struct VerifyView: View {
    
    @State var verifiedScale = 0.0
    @State var showQrScanner = false
    @StateObject var qrScannerViewModel: QRScannerViewModel
    
    @State private var verificationInProgress = false
    
    init() {
        _qrScannerViewModel = StateObject(
            wrappedValue: QRScannerViewModel(
                loadingMessageKey: "loading",
                instructionMessageKey: "verify.scan_qr"
            )
        )
    }
    
    func qrScanComplete(url: String) {
        guard let rootViewController = UIUtilities.getRootViewController() else {
            print("rootViewController was null, cannot launch verify")
            return
        }
        
        PingOneVerifyHelper.initialize(with: url, rootViewController: rootViewController) { helper, error  in
            if let error {
                print(error.localizedDescription!)
                ToastPresenter.show(style: .error, toast: String(localized: "verify.launch_error"))
                return
            }
            
            helper?.start()
        }
    }

    var body: some View {
        VStack {
            Text(LocalizedStringKey("verify.message"))
                .font(.system(size: 14))
            Spacer()

            VStack {
                Spacer()
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 150))
                    .foregroundStyle(Color(K.Colors.Primary))
                Text(LocalizedStringKey("verify.success"))
                    .font(.system(size: 24))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(K.Colors.Primary))
                Spacer()
            }
            .scaleEffect(verifiedScale)
            .animation(.easeInOut(duration: 1), value: verifiedScale)

            Button(LocalizedStringKey("verify.identity")) {
                GoogleAnalytics.userTappedButton(buttonName: "verify_identity")
                showQrScanner = true
                
            }
            .buttonStyle(BXFullWidthButtonStyle())
        }
        .padding()
        .popover(isPresented: $showQrScanner) {
            QRScannerView()
                .environmentObject(qrScannerViewModel)
        }
        .onChange(of: qrScannerViewModel.scanResult) { _, newValue in
            guard let url = newValue else {
                return
            }
            
            DispatchQueue.main.async {
                showQrScanner = false
                qrScannerViewModel.scanResult = nil
                qrScanComplete(url: url)
            }
        }
    }
}

#if DEBUG
struct VerifyView_Previews: PreviewProvider {
    static var previews: some View {
        VerifyView()
    }
}
#endif
