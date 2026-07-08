//
//  HomeWalletView.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 8/11/25.
//

import SwiftUI

struct HomeWalletView: View {
    
    @Binding var presentSideMenu: Bool
    
    @EnvironmentObject var walletModel: WalletViewModel
    @EnvironmentObject var walletAppModel: WalletAppViewModel
    
    var body: some View {
        
        ZStack {
            NavigationStack {
                CredentialListView(credentials: walletModel.credentials, credentialDescriptionAttribute: walletAppModel.credentialDescriptionKey, credentialIssuedAttribute: walletAppModel.credentialIssueDateKey)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                presentSideMenu.toggle()
                            }, label: {
                                VStack {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 20))
                                }
                            })
                            .tint(.bxPrimary)
                        }
                        ToolbarItem(placement: .principal) {
                            if walletAppModel.appLogoUrl.isEmpty && walletAppModel.selectedTheme != .Custom {
                                Image("\(walletAppModel.selectedTheme.rawValue)Logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200)
                            } else {
                                AsyncImage(url: URL(string: walletAppModel.appLogoUrl)) { image in
                                    image.resizable()
                                } placeholder: {
                                    Image("BXWalletLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200)
                                }
                                .scaledToFit()
                                .frame(width: 200)
                            }
                        }
                    }
                    .navigationTitle("credentials")
            }
            .tint(.bxPrimary)
            .padding(.bottom, 80)
            BottomBarView()
        }
        .fullScreenCover(isPresented: $walletModel.presentCredentialPicker) {
            NavigationStack {
                CredentialListView(credentials: walletModel.matchingCredentials, isSelecting: true, credentialDescriptionAttribute: walletAppModel.credentialDescriptionKey, credentialIssuedAttribute: walletAppModel.credentialIssueDateKey)
                    .navigationTitle("wallet.choose_credential")
            }
            .tint(.bxPrimary)
        }
    }
    
}

#Preview {
    @Previewable @State var present = false
    HomeWalletView(presentSideMenu: $present)
}

