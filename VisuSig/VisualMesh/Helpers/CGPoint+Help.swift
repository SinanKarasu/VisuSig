//
//  CGPoint+Help.swift
//  Spiral5
//
//  Created by Warren Burton on 29/12/2019.
//  Copyright © 2019 Warren Burton. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    func translatedBy(x: CGFloat = 0.0, y: CGFloat = 0.0) -> CGPoint {
        return CGPoint(x: self.x + x,
                       y: self.y + y)
    }
}

extension CGPoint {

    func alignCenterInParent(_ parent: CGSize) -> CGPoint {
        let x = parent.width/2 + self.x
        let y = parent.height/2 + self.y
        return CGPoint(x: x, y: y)
    }

    func scaledFrom(_ factor: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * factor,
                       y: self.y * factor)
    }
}

extension CGSize {
    func scaledDownTo(_ factor: CGFloat) -> CGSize {
        return CGSize(width: width/factor, height: height/factor)
    }

    var length: CGFloat {
        return sqrt(pow(width, 2) + pow(height, 2))
    }

    var inverted: CGSize {
        return CGSize(width: -width, height: -height)
    }

}

//extension CGPoint {
//
//    func transformedAndScaledNode( parent: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
//        self
//        .scaledFrom(zoomScale)
//        .alignCenterInParent(parent)
//        .translatedBy(x: portalPosition.x, y: portalPosition.y)
//    }
//
//    func transformedAndScaledPort( parent: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
//        print("center align:\(parent)")
//        return self
//        .scaledFrom(zoomScale)
//        .alignCenterInParent(parent)
//        .translatedBy(x: portalPosition.x, y: portalPosition.y)
//    }

//}
