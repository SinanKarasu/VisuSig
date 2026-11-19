//
//  PluginInterfaceView.swift
//  VisuSig
//

import AVFoundation
import CoreAudioKit
import SwiftUI

/// Hosts an Audio Unit's own interface at the size the plug-in asks for.
///
/// On macOS a plug-in hands the host an `NSViewController` however it draws
/// its interface (AppKit, or SwiftUI inside). The controller is hosted
/// directly, never squeezed into a fixed box: when the available space is
/// smaller than the plug-in, the interface scrolls; when it is larger, the
/// interface is centred.
struct PluginInterfaceView: View {
    let audioUnit: AUAudioUnit
    /// Called once the interface has loaded, with the size it asked for.
    var onSizeResolved: (CGSize) -> Void = { _ in }

    @State private var controller: NSViewController?
    @State private var size: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            if let controller {
                ScrollView([.horizontal, .vertical]) {
                    PluginControllerView(controller: controller)
                        .frame(width: size.width, height: size.height)
                        .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                }
            } else {
                ProgressView("Loading interface…")
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .task(id: ObjectIdentifier(audioUnit)) {
            controller = nil
            let custom = await audioUnit.requestViewController()
            guard !Task.isCancelled else { return }
            let resolved: NSViewController
            if let custom {
                resolved = custom
            } else {
                let generic = AUGenericViewController()
                generic.auAudioUnit = audioUnit
                resolved = generic
            }
            size = Self.preferredSize(of: resolved)
            controller = resolved
            onSizeResolved(size)
        }
    }

    /// The plug-in's preferred size, falling back to its view's own size.
    static func preferredSize(of controller: NSViewController) -> CGSize {
        let preferred = controller.preferredContentSize
        if preferred.width >= 50, preferred.height >= 50 { return preferred }
        let view = controller.view
        let fitting = view.fittingSize
        if fitting.width >= 50, fitting.height >= 50 { return fitting }
        if view.frame.width >= 50, view.frame.height >= 50 { return view.frame.size }
        return CGSize(width: 600, height: 300)
    }
}

private struct PluginControllerView: NSViewControllerRepresentable {
    let controller: NSViewController

    func makeNSViewController(context: Context) -> NSViewController { controller }
    func updateNSViewController(_ controller: NSViewController, context: Context) {}
}
