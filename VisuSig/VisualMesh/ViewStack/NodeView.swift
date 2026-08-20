import SwiftUI

struct NodeView: View {
    var node: NodeBase
    var selection: SelectionHandler
    var mesh: Mesh

    var selected: Bool { selection.isNodeSelected(node) }

    // MARK: - Color palette by role

    var nodeGradient: LinearGradient {
        let colors: [Color]
        if node.payload?.kind == .atlasStatement {
            colors = [Color(red: 0.08, green: 0.55, blue: 0.62), Color(red: 0.04, green: 0.32, blue: 0.42)]
        } else {
            switch node.nodeRole {
            case .source:  colors = [Color(red: 0.18, green: 0.46, blue: 0.90), Color(red: 0.10, green: 0.30, blue: 0.70)]
            case .effect:  colors = [Color(red: 0.55, green: 0.22, blue: 0.80), Color(red: 0.38, green: 0.12, blue: 0.60)]
            case .output:  colors = [Color(red: 0.15, green: 0.65, blue: 0.40), Color(red: 0.08, green: 0.45, blue: 0.25)]
            case .generic: colors = [Color(red: 0.35, green: 0.35, blue: 0.40), Color(red: 0.20, green: 0.20, blue: 0.25)]
            }
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
                    if mesh.runtime(for: node, as: AUManagedUnit.self) != nil {
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
        PluginWindowController.open(for: node, in: mesh)
    }
}
