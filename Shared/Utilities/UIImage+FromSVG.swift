//
//  UIImage+FromSVG.swift
//  BXMobileApps-iOS
//
//  Created by Eric Anderson on 10/4/24.
//

import Foundation
import UIKit
import PingOneWallet
import DIDSDK
import SVGKit

extension UIImage {
    
    static func fromClaim(_ claim: Claim, size: CGSize?) -> UIImage? {
        if let cardImageStr = CredentialUtils.getCardImageFromClaim(claim) ?? claim.getData()[ClaimKeys.cardImage] {
           return fromSvg(cardImageStr, size: size)
        }
        PingOneWallet.logerror("Failed to parse svg image")
        return nil
    }
    
    static func fromSvg(_ svg: String, size: CGSize?) -> UIImage? {
        if let svgImage = SVGKImage(data: svg.toData()) {
            if let size = size {
                svgImage.scaleToFit(inside: size)
            }
            return svgImage.uiImage
        }
        return nil
    }
    
}
