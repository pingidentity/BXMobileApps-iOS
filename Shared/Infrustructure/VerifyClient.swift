//
//  VerifyClient.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 12/13/24.
//

//import SwiftUI
//import PingOneVerify
//
//class VerifyClient {
//
//    private var submissionName = ""
//    
//    private let submissionCompleteCallback: (String) -> Void
//    private let submissionErrorCallback: (String) -> Void
//    
//    init(submissionCompleteCallback: @escaping (String) -> Void, submissionErrorCallback: @escaping (String) -> Void) {
//        self.submissionCompleteCallback = submissionCompleteCallback
//        self.submissionErrorCallback = submissionErrorCallback
//    }
//    
//    func launchVerify(primaryColor: Color? = nil) {
//        guard let rootViewController = UIUtilities.getRootViewController() else {
//            print("rootViewController was null, cannot launch verify")
//            return
//        }
//        
//        let primaryColor = (primaryColor != nil ? UIColor(primaryColor!) : UIColor(named: K.Colors.Primary)) ?? .accent
//        
//        let solidButtonAppearance = ButtonAppearance(backgroundColor: primaryColor, textColor: .white, borderColor: primaryColor)
//        let borderedButtonAppearance = ButtonAppearance(backgroundColor: .white, textColor: .black, borderColor: primaryColor)
//        
//        var appearanceSettings = UIAppearanceSettings()
//            .setSolidButtonAppearance(solidButtonAppearance)
//            .setBorderedButtonAppearance(borderedButtonAppearance)
//            .setBackgroundColor(.white)
//            .setBodyTextColor(.black)
//            .setHeadingTextColor(.white)
//            .setNavigationBarColor(primaryColor)
//            .setNavigationBarTextColor(.white)
//        
//        if let logo = UIImage(named: "LogoWhite") {
//            appearanceSettings = appearanceSettings.setLogoImage(logo)
//        }
//        
//        PingOneVerifyClient.Builder(isOverridingAssets: false)
//            .setListener(self)
//            .setRootViewController(rootViewController)
//            .setUIAppearance(appearanceSettings)
//            .startVerification { pingOneVerifyClient, clientBuilderError in
//                if let clientBuilderError {
//                    logerror(clientBuilderError.localizedDescription ?? "Unknown error occurred")
//                    self.submissionErrorCallback("An error occurred starting verification: \(clientBuilderError.localizedDescription ?? "unknown error")")
//                }
//            }
//    }
//}
//
//extension VerifyClient: DocumentSubmissionListener {
//    func onDocumentSubmitted(response: DocumentSubmissionResponse) {
//        print("The document status is \(String(describing: response.documentStatus))")
//        print("The document submission status is \(String(describing: response.documentSubmissionStatus))")
//        
//        guard let documents = response.document else { return }
//        for (key, value) in documents {
//            print("\(key): \(value)")
//        }
//        
//        if let verifiedFirstName = documents["firstName"],
//           let verifiedLastName = documents["lastName"] {
//            self.submissionName = "\(verifiedFirstName) \(verifiedLastName)"
//        }
//    }
//    
//    func onSubmissionComplete(status: DocumentSubmissionStatus) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // need to wait for verify to close
//            self.submissionCompleteCallback("Document submission successful\(self.submissionName != "" ? " for \(self.submissionName)" : "")")
//            self.submissionName = ""
//        }
//    }
//    
//    func onSubmissionError(error: DocumentSubmissionError) {
//        print(error.localizedDescription ?? "Unknown submission error occurred")
//        self.submissionErrorCallback(error.localizedDescription ?? "Unknown submission error occurred")
//    }
//}
