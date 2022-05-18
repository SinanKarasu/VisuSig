/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Small extensions to simplify view handling in the demo app.
*/

import SwiftUI

public extension NSView {
    @discardableResult
    func pinToSuperview() -> NSView {
        guard let superview = superview else { return self}
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])
        return self
    }
}
