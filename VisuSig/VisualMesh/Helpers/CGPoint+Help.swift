// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Sinan Karasu

import CoreGraphics

extension CGPoint {
    func translatedBy(x: CGFloat = 0, y: CGFloat = 0) -> CGPoint {
        CGPoint(x: self.x + x, y: self.y + y)
    }

    func alignCenterInParent(_ parent: CGSize) -> CGPoint {
        CGPoint(x: parent.width / 2 + x, y: parent.height / 2 + y)
    }

    func scaledFrom(_ factor: CGFloat) -> CGPoint {
        CGPoint(x: x * factor, y: y * factor)
    }
}

extension CGSize {
    func scaledDownTo(_ factor: CGFloat) -> CGSize {
        CGSize(width: width / factor, height: height / factor)
    }

    var length: CGFloat {
        hypot(width, height)
    }

    var inverted: CGSize {
        CGSize(width: -width, height: -height)
    }
}
