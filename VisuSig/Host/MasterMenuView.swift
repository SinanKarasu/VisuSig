//
//  MasterMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/8/22.
//

import SwiftUI
import VisualMesh
import VisualMeshExamples

struct MasterMenuView: View {
    enum Workspace: String, CaseIterable, Identifiable {
        case payload = "Payload"
        case hierarchy = "Hierarchy"
        case audioUnits = "Audio Units"
        case midi = "MIDI"
        case daw = "DAW"

        var id: Self { self }
    }

    @State private var workspace: Workspace = .hierarchy
    @State private var visitedWorkspaces: Set<Workspace> = [.hierarchy]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("VisuSig")
                    .font(.headline)
                Picker("Workspace", selection: $workspace) {
                    ForEach(Workspace.allCases) { workspace in
                        Text(workspace.rawValue).tag(workspace)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 420)
                Spacer()
                Text(workspace.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(.bar)

            ZStack {
                ForEach(Workspace.allCases) { item in
                    if visitedWorkspaces.contains(item) || item == workspace {
                        workspaceView(item)
                            .opacity(item == workspace ? 1 : 0)
                            .allowsHitTesting(item == workspace)
                            .accessibilityHidden(item != workspace)
                    }
                }
            }
            .onChange(of: workspace) { _, selected in
                visitedWorkspaces.insert(selected)
            }
        }
        .frame(minWidth: 1100, minHeight: 720)
    }

    @ViewBuilder
    private func workspaceView(_ workspace: Workspace) -> some View {
        switch workspace {
        case .payload:
            PayloadWorkbenchView()
        case .hierarchy:
            HierarchyWorkbenchView()
        case .audioUnits:
            AudioUnitWorkspaceView()
        case .midi:
            MIDIWorkspace()
        case .daw:
            DAWWorkspace()
        }
    }

}

private extension MasterMenuView.Workspace {
    var explanation: String {
        switch self {
        case .payload:
            return "Payloads are durable; runtimes are adapters."
        case .hierarchy:
            return "Definitions are reusable; instances carry identity and wiring context."
        case .audioUnits:
            return "Apple Audio Units through the Payload adapter."
        case .midi:
            return "Live MIDI and audio-file playback through one mixer."
        case .daw:
            return "Audio and MIDI sources routed into one mixer."
        }
    }
}

@MainActor
@Observable
private final class HierarchyWorkbenchModel {
    let library: MeshLibrary<WITSComponent, WITSNet>
    let board: VisualMesh.Mesh<WITSComponent, WITSNet>
    let resistorPackDefinitionID: MeshDefinitionID

    var expandedInstanceIDs: Set<UUID> = []
    var selectedInstanceID: UUID?
    var errorMessage: String?

    init() {
        do {
            let example = try WITSHierarchyExample.make()
            library = example.library
            board = example.board
            resistorPackDefinitionID = example.resistorPackDefinitionID
            selectedInstanceID = board.nodes.first?.id
        } catch {
            preconditionFailure("Unable to build the hierarchy example: \(error)")
        }
    }

    var packDefinition: MeshDefinition<WITSComponent, WITSNet>? {
        library.definition(id: resistorPackDefinitionID)
    }

    func addPackInstance() {
        guard let definition = packDefinition else { return }
        let number = 100 + board.nodes.count
        let designator = "U\(number)"

        do {
            let instance = try library.instantiate(
                definitionID: definition.id,
                designator: designator,
                payload: WITSComponent(
                    kind: .pack,
                    designator: designator,
                    description: "RESSIP9 instance"
                )
            )
            let previous = board.nodes.last
            board.addNode(instance)
            if let previous {
                try board.connect(
                    sourceNodeID: previous.id,
                    sourcePortID: previous.ports[1].id,
                    targetNodeID: instance.id,
                    targetPortID: instance.ports[1].id,
                    payload: WITSNet(name: "CARD-NET-\(board.edges.count + 1)")
                )
            }
            selectedInstanceID = instance.id
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }

    func toggleExpanded(_ nodeID: UUID) {
        if expandedInstanceIDs.contains(nodeID) {
            expandedInstanceIDs.remove(nodeID)
        } else {
            expandedInstanceIDs.insert(nodeID)
        }
    }

    func nodeTitle(_ nodeID: UUID) -> String {
        board.nodes.first { $0.id == nodeID }?.subgraph?.designator ?? "?"
    }

    func portName(_ portID: UUID, on nodeID: UUID) -> String {
        board.nodes
            .first { $0.id == nodeID }?
            .ports.first { $0.id == portID }?
            .name ?? "?"
    }
}

private struct HierarchyWorkbenchView: View {
    @State private var model = HierarchyWorkbenchModel()

    var body: some View {
        HSplitView {
            libraryPane
                .frame(minWidth: 240, idealWidth: 270, maxWidth: 320)

            VStack(alignment: .leading, spacing: 0) {
                header
                Divider()
                assemblyCanvas
                Divider()
                netList
                    .frame(height: 130)
            }
            .frame(minWidth: 760)
        }
    }

    private var libraryPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Definition library", systemImage: "books.vertical")
                .font(.headline)

            ForEach(model.library.definitions) { definition in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(.indigo)
                        Text(definition.name)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                    }
                    Text(definition.title)
                        .font(.caption)
                    Text("\(definition.mesh.nodes.count) internal nodes · \(definition.interfacePorts.count) boundary ports")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.65), in: RoundedRectangle(cornerRadius: 9))
            }

            Divider()

            VStack(alignment: .leading, spacing: 7) {
                Label("Standards correspondence", systemImage: "arrow.triangle.branch")
                    .font(.subheadline.weight(.semibold))
                correspondence("WITS", "PACK definition / designator")
                correspondence("TEDL", "device model / DEVICE binding")
                correspondence("IEEE 1671", "description / instance reference")
                correspondence("ATML interface", "Ports + NetworkList")
            }

            Spacer()

            Text("Software instruments will attach to edges and boundary nets later; they do not change this hierarchy model.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func correspondence(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(name)
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hierarchical VisualMesh")
                    .font(.title2.weight(.semibold))
                Text("One RESSIP9 definition; independently wired U100…Un instances.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let errorMessage = model.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Button("Add RESSIP9 Instance", systemImage: "plus.rectangle.on.rectangle") {
                model.addPackInstance()
            }
        }
        .padding(12)
    }

    private var assemblyCanvas: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 28) {
                ForEach(Array(model.board.nodes.enumerated()), id: \.element.id) { index, node in
                    if index > 0 {
                        VStack(spacing: 4) {
                            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                                .font(.title2)
                            Text(model.board.edges.indices.contains(index - 1)
                                 ? model.board.edges[index - 1].payload.name
                                 : "unwired")
                                .font(.caption2.monospaced())
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 88)
                        .padding(.top, 45)
                    }

                    packBox(node)
                }
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [Color.indigo.opacity(0.06), Color.cyan.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func packBox(_ node: GraphNode<WITSComponent>) -> some View {
        let definition = model.library.definition(for: node)
        let expanded = model.expandedInstanceIDs.contains(node.id)
        let selected = model.selectedInstanceID == node.id

        return VStack(spacing: 0) {
            Button {
                model.selectedInstanceID = node.id
                model.toggleExpanded(node.id)
            } label: {
                HStack {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                    VStack(alignment: .leading, spacing: 1) {
                        Text(node.subgraph?.designator ?? node.title)
                            .font(.headline.monospaced())
                        Text(definition?.name ?? "Missing definition")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "shippingbox")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(12)

            Divider()

            if let definition {
                boundaryPorts(node.ports)
                    .padding(10)

                if expanded {
                    Divider()
                    definitionInterior(definition)
                        .padding(10)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
        }
        .frame(width: expanded ? 430 : 280)
        .background(.background, in: RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: selected ? 2.5 : 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .animation(.snappy, value: expanded)
    }

    private func boundaryPorts(_ ports: [GraphPort]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
            ForEach(ports) { port in
                Text(port.name.replacingOccurrences(of: "PACK-", with: ""))
                    .font(.caption2.monospaced().weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.16), in: Capsule())
                    .help(port.name)
            }
        }
    }

    private func definitionInterior(
        _ definition: MeshDefinition<WITSComponent, WITSNet>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Shared definition", systemImage: "square.stack.3d.up.fill")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("not copied into instance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 7) {
                ForEach(definition.mesh.nodes) { internalNode in
                    VStack(spacing: 2) {
                        Text(internalNode.title)
                            .font(.caption.monospaced().weight(.bold))
                        Text(internalNode.payload.description)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.orange.opacity(0.13), in: RoundedRectangle(cornerRadius: 6))
                }
            }

            Divider()

            ForEach(definition.boundaryBindings) { binding in
                Text(bindingDescription(binding, in: definition))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func bindingDescription(
        _ binding: GraphBoundaryBinding,
        in definition: MeshDefinition<WITSComponent, WITSNet>
    ) -> String {
        let boundary = definition.boundaryPort(id: binding.boundaryPortID)?.name ?? "?"
        let endpoints = binding.internalEndpoints.compactMap { endpoint -> String? in
            guard let node = definition.mesh.nodes.first(where: { $0.id == endpoint.nodeID }),
                  let port = node.ports.first(where: { $0.id == endpoint.portID })
            else { return nil }
            return "\(node.title)-\(port.name)"
        }
        return "\(boundary) → \(endpoints.joined(separator: " "))"
    }

    private var netList: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Assembly nets cross instance boundaries", systemImage: "point.3.filled.connected.trianglepath.dotted")
                .font(.subheadline.weight(.semibold))

            if model.board.edges.isEmpty {
                Text("No instance connections")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.board.edges) { edge in
                    Text(
                        "\(edge.payload.name): " +
                        "\(model.nodeTitle(edge.sourceNodeID)).\(model.portName(edge.sourcePortID, on: edge.sourceNodeID)) ↔ " +
                        "\(model.nodeTitle(edge.targetNodeID)).\(model.portName(edge.targetPortID, on: edge.targetNodeID))"
                    )
                    .font(.caption.monospaced())
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct AudioUnitWorkspaceView: View {
    @State private var audioUnitComponents = AudioUnitComponents()

    /// AudioGraph remains an adapter over the domain-neutral visual mesh.
    @State private var audioGraph: AudioGraph = Mesh.sampleMesh() as! AudioGraph

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {

                // ── Transport bar ──────────────────────────────────────
                SiKPlayerView(audioGraph: audioGraph) { url in
                    audioUnitComponents.setPreviewAudioFile(url: url)
                }
                    .frame(height: 60)
                    .background(Color.black.opacity(0.85))

                // ── Node graph canvas ──────────────────────────────────
                SurfaceView(mesh: audioGraph, audioUnitComponents: audioUnitComponents)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── AU preview panel (for auditioning individual effects) ──
                Divider()
                EffectsMenuSplitView(audioUnitComponents: audioUnitComponents)
                    .frame(height: 280)
            }
            .onAppear {
                if let url = audioGraph.audioFileURL {
                    audioUnitComponents.setPreviewAudioFile(url: url)
                }
            }
        }
    }
}

struct MasterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MasterMenuView()
    }
}
