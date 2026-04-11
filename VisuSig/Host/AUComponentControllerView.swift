//
//  AUComponentControllerView.swift
//  VisuSig
//

import SwiftUI

struct AUComponentControllerView: NSViewControllerRepresentable {
    var componentViewController: ComponentViewController
    var size: CGSize

    func makeNSViewController(context: Context) -> NSViewController {
        logger.info("Making controller")
        return componentViewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
