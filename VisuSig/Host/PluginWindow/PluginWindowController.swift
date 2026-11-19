//
//  PluginWindowController.swift
//  VisuSig
//

import AppKit
import AVFoundation
import SwiftUI

/// A floating, non-modal window showing a plug-in's own interface, sized to
/// what the plug-in asks for. One window per graph node: opening it again
/// brings the existing window forward. The controller keeps itself alive in
/// `openWindows` until the window closes.
final class PluginWindowController: NSWindowController, NSWindowDelegate {
    private static var openWindows: Set<PluginWindowController> = []

    /// Opens (or brings forward) the plugin window for a graph node.
    static func open(nodeID: UUID, title: String, unit payload: AUManagedUnit) {
        if let existing = openWindows.first(where: { $0.nodeID == nodeID }) {
            existing.showWindow(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        guard let audioUnit = payload.audioUnit else { return }
        let controller = PluginWindowController(nodeID: nodeID, title: title, audioUnit: audioUnit)
        controller.showWindow(nil)
    }

    private let nodeID: UUID

    private init(nodeID: UUID, title: String, audioUnit: AUAudioUnit) {
        self.nodeID = nodeID

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false   // lifetime is managed by openWindows
        window.center()

        super.init(window: window)
        window.delegate = self

        // Resize the window to the plug-in's preferred size once it loads.
        window.contentView = NSHostingView(rootView: PluginInterfaceView(audioUnit: audioUnit) { [weak window] size in
            guard let window else { return }
            window.setContentSize(size)
            window.contentMinSize = CGSize(width: min(size.width, 320), height: min(size.height, 160))
            window.center()
        })

        Self.openWindows.insert(self)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func windowWillClose(_ notification: Notification) {
        Self.openWindows.remove(self)
    }
}
