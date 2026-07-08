//
//  DashboardScreen.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 2/11/25.
//

import SwiftUI
import FirebaseAnalytics

struct DashboardScreen: View {
    enum Tab {
        case pair
        case verify
        case results
        case messages
        case doctor
    }
    
    @State var selection: Tab = .pair
    
    var body: some View {
        LogoView(assetName: K.Assets.Logo)
        
        TabView(selection: $selection) {
            VStack {
                PairDeviceView()
                    .onAppear {
                        GoogleAnalytics.userViewedScreen(screenName: "pair_device")
                    }
            }
            .tabItem {
                Text(LocalizedStringKey("pair_device"))
                Image(systemName: "iphone.gen2")
            }.tag(Tab.pair)
            
            VStack {
                VerifyView()
                    .onAppear {
                        GoogleAnalytics.userViewedScreen(screenName: "verify_identity")
                    }
            }
            .tabItem {
                Text(LocalizedStringKey("verify_user"))
                Image(systemName: "person.badge.shield.checkmark.fill")
            }.tag(Tab.verify)
            
            Text(LocalizedStringKey("test_results")).tabItem {
                Text(LocalizedStringKey("test_results"))
                Image(systemName: "testtube.2")
            }.tag(Tab.results)
            
            
            Text(LocalizedStringKey("messages")).tabItem {
                Text(LocalizedStringKey("messages"))
                Image(systemName: "message")
            }.tag(Tab.messages)
        
        }
        .tint(Color(K.Colors.Primary))
        .onChange(of: selection) { oldValue, newValue in
            // Pair and Verify are the only two tabs that should be accessible
            if newValue != .pair && newValue != .verify {
                selection = oldValue
            }
        }
    }
}
