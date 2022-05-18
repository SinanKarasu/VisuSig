//
//  Utilities+Extensions.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/18/22.
//

import Foundation


extension Comparable {
    // ie: 5.clamped(to: 7...10)
    // ie: 5.0.clamped(to: 7.0...10.0)
    // ie: "a".clamped(to: "b"..."h")
    /// **OTCore:**
    /// Returns the value clamped to the passed range.
    @inlinable internal func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
