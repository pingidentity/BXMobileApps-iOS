//
//  WalletView.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 12/13/24.
//

import SwiftUI

struct WalletView: View {
    
    @EnvironmentObject var router: RouterViewModel
    @EnvironmentObject var walletModel: WalletViewModel

    private let applicationUiHandler = ApplicationUiHandler()
    
    var body: some View {

        CredentialListView(credentials: walletModel.credentials, isSelecting: false, credentialDescriptionAttribute: "Email", credentialIssuedAttribute: "Issued")
        
        Button(action: {
            GoogleAnalytics.userTappedButton(buttonName: "scan_credential_verification_qr")
            Task {
                await CameraAccess.checkCameraAccess(applicationUiHandler: applicationUiHandler) {
                    walletModel.presentQrScanner = true
                }
            }
        }) {
            Image(systemName: "qrcode.viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35) // Adjust size as needed
                .foregroundColor(.white) // Set image color
                .padding(8)
        }
        .buttonStyle(BXButtonStyle())
        .clipShape(Circle())
        .shadow(radius: 5)
        .padding(.bottom, 24)
        .fullScreenCover(isPresented: $walletModel.presentCredentialPicker) {
            NavigationStack {
                CredentialListView(credentials: walletModel.matchingCredentials, isSelecting: true, credentialDescriptionAttribute: "Email", credentialIssuedAttribute: "Issued")
                    .navigationTitle("wallet.choose_credential")
            }
            .tint(Color(K.Colors.Primary))
        }
        .popover(isPresented: $walletModel.presentQrScanner) {
            QRScannerView()
                .environmentObject(walletModel.qrScannerModel)
        }
    }
}

#Preview {
    WalletView()
        .environmentObject(RouterViewModel())
}
