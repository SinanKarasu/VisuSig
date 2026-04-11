import SwiftUI

struct NodeView: View {
    var node: NodeBase
    var selection: SelectionHandler

    var selected: Bool { selection.isNodeSelected(node) }

    // MARK: - Color palette by role

    var nodeGradient: LinearGradient {
        let colors: [Color]
        switch node.nodeRole {
        case .source:  colors = [Color(red: 0.18, green: 0.46, blue: 0.90), Color(red: 0.10, green: 0.30, blue: 0.70)]
        case .effect:  colors = [Color(red: 0.55, green: 0.22, blue: 0.80), Color(red: 0.38, green: 0.12, blue: 0.60)]
        case .output:  colors = [Color(red: 0.15, green: 0.65, blue: 0.40), Color(red: 0.08, green: 0.45, blue: 0.25)]
        case .generic: colors = [Color(red: 0.35, green: 0.35, blue: 0.40), Color(red: 0.20, green: 0.20, blue: 0.25)]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var borderColor: Color {
        selected ? Color.yellow : Color.white.opacity(0.35)
    }

    var borderWidth: CGFloat { selected ? 2.5 : 1.0 }

    // Port circle radius (must match PortBase.defaultSize / 2)
    private let portRadius: CGFloat = 18

    var body: some View {
        ZStack {
            // ── Input ports row (above node body) ──────────────────────
            if !node.inputPorts.isEmpty {
                HStack(spacing: 6) {
                    ForEach(node.inputPorts, id: \.self) { port in
                        PortView(port: port, selection: selection)
                    }
                }
                .offset(y: -(node.size.height / 2.0 + portRadius))
            }

            // ── Node body ──────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 12)
                .fill(nodeGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .overlay(node.nodeInfo)
                .frame(width: node.size.width, height: node.size.height)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                .contextMenu {
                    if node.nodeRole == .effect {
                        Button("Open Plugin UI") {
                            openPluginGUI()
                        }
                        Divider()
                        Button("Add Input Port") {
                            DispatchQueue.main.async {
                                node.addPort(port: PortBase(node: node, name: "In \(node.inputPorts.count + 1)", portType: .input))
                            }
                        }
                        Button("Add Output Port") {
                            DispatchQueue.main.async {
                                node.addPort(port: PortBase(node: node, name: "Out \(node.outputPorts.count + 1)", portType: .output))
                            }
                        }
                    }
                }
                .onTapGesture {
                    selection.selectNode(node)
                }

            // ── Output ports row (below node body) ─────────────────────
            if !node.outputPorts.isEmpty {
                HStack(spacing: 6) {
                    ForEach(node.outputPorts, id: \.self) { port in
                        PortView(port: port, selection: selection)
                    }
                }
                .offset(y: node.size.height / 2.0 + portRadius)
            }

            // ── Flyout action menu on selection ────────────────────────
            if selected {
                flyoutMenu()
                    .offset(x: node.size.width / 2.0 + 20, y: 0)
            }
        }
        .offset(x: node.position.x, y: node.position.y)
        .frame(width: node.size.width, height: node.size.height, alignment: .center)
        .coordinateSpace(name: node.id.uuidString)
    }

    // MARK: - Flyout menu

    func flyoutMenu() -> some View {
        let flyoutMenuOptions = MenuOptions().setupOptions()
        return FlyoutMenuMainView(flyoutMenuOptions: flyoutMenuOptions)
    }

    // MARK: - Plugin GUI

    private func openPluginGUI() {
        PluginWindowController.open(for: node)
    }
}

// MARK: - Plugin Window Controller

/// Opens a floating, non-modal NSWindow showing the native AU plugin GUI.
/// Retains itself via the static `openWindows` set until the user closes the window.
final class PluginWindowController: NSWindowController, NSWindowDelegate {

    private static var openWindows: Set<PluginWindowController> = []

    static func open(for node: NodeBase) {
        guard let payload = node.payload else { return }

        // Bring forward if already open for this node.
        if let existing = openWindows.first(where: { $0.nodeID == node.id }) {
            existing.showWindow(nil)
            return
        }

        payload.loadAudioUnitViewController { vc in
            payload.setController(controller: vc)
            let controller = PluginWindowController(node: node, payload: payload)
            controller.showWindow(nil)
        }
    }

    private let nodeID: UUID

    private init(node: NodeBase, payload: AUManagedUnit) {
        self.nodeID = node.id

        let hostingView = NSHostingView(
            rootView: PluginGUIContent(payload: payload)
        )
        hostingView.sizingOptions = .preferredContentSize

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = node.text
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)
        window.delegate = self
        Self.openWindows.insert(self)
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func windowWillClose(_ notification: Notification) {
        Self.openWindows.remove(self)
    }
}

// MARK: - Plugin GUI Content

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
