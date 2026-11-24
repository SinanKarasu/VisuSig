//
//  PluginInterfaceView.swift
//  VisuSig
//

import AVFoundation
import CoreAudioKit
import SwiftUI

/// Hosts an Audio Unit's own interface at the size the plug-in asks for.
///
/// Desktop interfaces keep their natural size and scroll when necessary.
/// On iPadOS, resize flexible controllers to the panel and scale fixed-size
/// interfaces down to fit while preserving their aspect ratio.
struct PluginInterfaceView: View {
    let audioUnit: AUAudioUnit
    /// Called once the interface has loaded, with the size it asked for.
    var onSizeResolved: (CGSize) -> Void = { _ in }

    @State private var controller: PluginViewController?
    @State private var size: CGSize = .zero
    @State private var usesFlexibleLayout = false

    var body: some View {
        GeometryReader { proxy in
            if let controller {
                #if os(macOS)
                ScrollView([.horizontal, .vertical]) {
                    PluginControllerView(controller: controller)
                        .frame(width: size.width, height: size.height)
                        .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                }
                #else
                if usesFlexibleLayout {
                    PluginControllerView(controller: controller)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    let scale = min(1, max(0, proxy.size.width) / size.width,
                                    max(0, proxy.size.height) / size.height)
                    PluginControllerView(controller: controller)
                        .frame(width: size.width, height: size.height)
                        .scaleEffect(scale, anchor: .topLeading)
                        .frame(width: size.width * scale, height: size.height * scale,
                               alignment: .topLeading)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                }
                #endif
            } else {
                ProgressView("Loading interface…")
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .task(id: ObjectIdentifier(audioUnit)) {
            controller = nil
            let custom = await audioUnit.requestViewController()
            guard !Task.isCancelled else { return }
            let resolved: PluginViewController
            if let custom {
                resolved = custom
            } else {
                let generic = AUGenericViewController()
                generic.auAudioUnit = audioUnit
                resolved = generic
            }
            #if !os(macOS)
            resolved.loadViewIfNeeded()
            resolved.view.setNeedsLayout()
            resolved.view.layoutIfNeeded()
            #endif
            #if os(macOS)
            size = Self.preferredSize(of: resolved)
            #else
            let preferred = resolved.preferredContentSize
            usesFlexibleLayout = !preferred.width.isFinite || !preferred.height.isFinite
                || preferred.width < 50 || preferred.height < 50
            // A controller without a preferred size is resizable. Its initial
            // view frame can be the entire iPad screen, not a natural UI size.
            size = usesFlexibleLayout ? CGSize(width: 600, height: 300) : preferred
            #endif
            controller = resolved
            onSizeResolved(size)
        }
    }

    /// The plug-in's preferred size, falling back to its view's own size.
    static func preferredSize(of controller: PluginViewController) -> CGSize {
        let preferred = controller.preferredContentSize
        if preferred.width.isFinite, preferred.height.isFinite,
           preferred.width >= 50, preferred.height >= 50 { return preferred }
        #if os(macOS)
        let view = controller.view
        #else
        guard let view = controller.view else { return CGSize(width: 600, height: 300) }
        #endif
        #if os(macOS)
        let fitting = view.fittingSize
        #else
        let fitting = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        #endif
        if fitting.width.isFinite, fitting.height.isFinite,
           fitting.width >= 50, fitting.height >= 50 { return fitting }
        if view.frame.width >= 50, view.frame.height >= 50 { return view.frame.size }
        return CGSize(width: 600, height: 300)
    }
}

#if os(macOS)
private struct PluginControllerView: NSViewControllerRepresentable {
    let controller: NSViewController

    func makeNSViewController(context: Context) -> NSViewController { controller }
    func updateNSViewController(_ controller: NSViewController, context: Context) {}
}

#else
private struct PluginControllerView: UIViewControllerRepresentable {
    let controller: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { controller }
    func updateUIViewController(_ controller: UIViewController, context: Context) {}
}
#endif
