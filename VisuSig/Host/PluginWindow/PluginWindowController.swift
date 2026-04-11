//
//  PluginWindowController.swift
//  VisuSig
//

import AppKit
import SwiftUI

/// Opens a floating, non-modal NSWindow showing the native AU plugin GUI.
/// The controller retains itself via the static `openWindows` set until the
/// user closes the window (red traffic-light button).
final class PluginWindowController: NSWindowController, NSWindowDelegate {

    // ── Lifetime management ──────────────────────────────────────────────
    // Inserting `self` here keeps the controller (and its window) alive.
    // Removing it on close lets ARC clean everything up.
    private static var openWindows: Set<PluginWindowController> = []

    // ── Public factory ───────────────────────────────────────────────────

    /// Call this from NodeView to open (or bring forward) the plugin window.
    static func open(for node: NodeBase) {
        guard let payload = node.payload else { return }

        // If a window for this node is already open, just bring it forward.
        if let existing = openWindows.first(where: { $0.nodeID == node.id }) {
            existing.showWindow(nil)
            return
        }

        // Load the AU view controller, then show the window on the main thread.
        payload.loadAudioUnitViewController { vc in
            payload.setController(controller: vc)
            let controller = PluginWindowController(node: node, payload: payload)
            controller.showWindow(nil)
        }
    }

    // ── Stored node identity (for de-duplication above) ──────────────────
    private let nodeID: UUID

    // ── Init ─────────────────────────────────────────────────────────────

    private init(node: NodeBase, payload: AUManagedUnit) {
        self.nodeID = node.id

        // Build the SwiftUI content and wrap it in an NSHostingView.
        let hostingView = NSHostingView(
            rootView: PluginGUIContent(payload: payload)
        )
        hostingView.sizingOptions = .preferredContentSize

        // Create a standard document-style window with all three traffic lights.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = node.text
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false   // we manage lifetime ourselves

        super.init(window: window)
        window.delegate = self

        // Retain self until the window closes.
        Self.openWindows.insert(self)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // ── NSWindowDelegate ─────────────────────────────────────────────────

    func windowWillClose(_ notification: Notification) {
        // Releasing self from the set lets ARC collect the controller + window.
        Self.openWindows.remove(self)
    }
}

// ── Plugin GUI content view ───────────────────────────────────────────────────

/// Wraps the AU's native NSViewController in a SwiftUI view.
private struct PluginGUIContent: View {
    var payload: AUManagedUnit

    var body: some View {
        AUComponentControllerView(
            componentViewController: payload.componentViewController,
            size: CGSize(width: 800, height: 500)
        )
        .frame(
            minWidth: 400,  idealWidth: 800,  maxWidth: .infinity,
            minHeight: 200, idealHeight: 500, maxHeight: .infinity
        )
    }
}
