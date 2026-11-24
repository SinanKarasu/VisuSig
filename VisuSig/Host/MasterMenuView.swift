//
//  MasterMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/8/22.
//

import SwiftUI
import VisualMesh
import VisualMeshExamples
import VisualMeshUI

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
    @State private var showsSettings = false
    @State private var projectToOpen: URL?
    @State private var projectAction: MusicProjectAction?
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
                #if os(macOS)
                Text(workspace.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #else
                Button("Settings", systemImage: "gearshape") { showsSettings = true }
                    .labelStyle(.iconOnly)
                #endif
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
        .frame(minWidth: PlatformUI.minimumWindowWidth, minHeight: 600)
        #if !os(macOS)
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                PreferencesView()
                    .navigationTitle("Settings")
                    .toolbar {
                        Button("Done") { showsSettings = false }
                    }
            }
        }
        .sheet(item: Binding(
            get: { PluginWindowController.shared.presentation },
            set: { PluginWindowController.shared.presentation = $0 }
        )) { plugin in
            NavigationStack {
                PluginInterfaceView(audioUnit: plugin.unit)
                    .navigationTitle(plugin.title)
                    .toolbar {
                        Button("Done") { PluginWindowController.shared.presentation = nil }
                    }
            }
        }
        #endif
        .focusedSceneValue(\.musicProjectActions, MusicProjectActions(
            open: {
                workspace = .audioUnits
                projectAction = .open
            },
            save: {
                workspace = .audioUnits
                projectAction = .save
            },
            saveAs: {
                workspace = .audioUnits
                projectAction = .saveAs
            }
        ))
        .onOpenURL { url in
            workspace = .audioUnits
            projectToOpen = url
        }
    }

    @ViewBuilder
    private func workspaceView(_ workspace: Workspace) -> some View {
        switch workspace {
        case .payload:
            PayloadWorkbenchView()
        case .hierarchy:
            HierarchyWorkbenchView()
        case .audioUnits:
            AudioUnitWorkspaceView(projectToOpen: $projectToOpen, projectAction: $projectAction)
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
            return "Audio and MIDI on one graph: instruments, MIDI and audio effects."
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
        WorkspaceSplitView {
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
            .frame(minWidth: PlatformUI.desktopMinimum(760))
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
        .background(PlatformUI.controlBackground)
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
        .background(PlatformUI.controlBackground)
    }
}

struct AudioUnitWorkspaceView: View {
    @Binding var projectToOpen: URL?
    @Binding var projectAction: MusicProjectAction?
    @State private var isOpeningProject = false
    #if !os(macOS)
    @State private var isImportingProject = false
    @State private var isExportingProject = false
    @State private var exportDocument: MusicProjectExport?
    @State private var pendingProjectURL: URL?
    @State private var openAfterExport: URL?
    @State private var confirmsProjectReplacement = false
    #endif

    init(projectToOpen: Binding<URL?> = .constant(nil),
         projectAction: Binding<MusicProjectAction?> = .constant(nil)) {
        _projectToOpen = projectToOpen
        _projectAction = projectAction
    }
    @State private var audioUnitComponents = AudioUnitComponents()

    /// AudioGraph is an adapter over the domain-neutral VisualMesh graph.
    @State private var audioGraph = AudioGraph.makeDefault()
    @State private var canvasState = MeshCanvasState()

    @State private var connectionError: String?

    @State private var showsLibrary = true
    @State private var showsBottomArea = true
    @State private var bottomPanel: BottomPanel = .mixer
    @State private var shownMixerID: UUID?
    @State private var auditionNodeID: UUID?
    @State private var librarySelection: Component.ID?
    @State private var canvasSize: CGSize = .zero
    @State private var auditionHeight: CGFloat = 280

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Text(audioGraph.projectURL?.deletingPathExtension().lastPathComponent ?? "Untitled Music Session")
                    .font(.headline)
                Spacer()
                Button("Open Project…") { chooseProject() }
                Button("Save Project") { _ = saveProject() }
                Button("Save As…") { _ = saveProject(saveAs: true) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            // ── Transport bar ──────────────────────────────────────
            HStack(spacing: 0) {
                panelToggle("Plug-in Library", systemImage: "sidebar.left", isOn: $showsLibrary)
                SiKPlayerView(audioGraph: audioGraph) { url in
                    audioUnitComponents.setPreviewAudioFile(url: url)
                }
                panelToggle("Mixer and Audition", systemImage: "rectangle.bottomthird.inset.filled", isOn: $showsBottomArea)
            }
            .frame(height: 60)
            .background(Color.black.opacity(0.85))

            WorkspaceSplitView {
                // ── Library (left, like Logic's browser) ───────────
                if showsLibrary {
                    PluginLibraryView(audioUnitComponents: audioUnitComponents,
                                      selection: Binding(
                                        get: { librarySelection },
                                        set: {
                                            auditionNodeID = nil
                                            librarySelection = $0
                                        }
                                      )) { component in
                        addPlugin(component, at: visibleCenter)
                    }
                    .frame(minWidth: 220, idealWidth: 270, maxWidth: 420)
                }

                VStack(spacing: 0) {
                    // ── Node graph canvas ──────────────────────────
                    canvas
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(minHeight: 200)
                        .overlay(alignment: .top) {
                            if let message = connectionError ?? audioGraph.lastError {
                                Label(message, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.regularMaterial, in: Capsule())
                                    .padding(8)
                                    .onTapGesture { connectionError = nil }
                            }
                        }

                    if !audioGraph.projectWarnings.isEmpty {
                        Text("Unavailable plug-ins (saved state retained): " + audioGraph.projectWarnings.joined(separator: "; "))
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .textSelection(.enabled)
                            .padding(8)
                    }

                    // ── Mixer, library preview, or selected graph plug-in ──
                    if showsBottomArea {
                        ResizeHandle(height: $auditionHeight, range: auditionHeightRange)
                        VStack(spacing: 0) {
                            Picker("Bottom area", selection: $bottomPanel) {
                                ForEach(BottomPanel.allCases) { Label($0.rawValue, systemImage: $0.systemImage).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .fixedSize()
                            .padding(.vertical, 4)
                            switch bottomPanel {
                            case .mixer:
                                MixerView(audioGraph: audioGraph, mixerID: mixerToShow)
                            case .audition:
                                EffectAuditionView(audioUnitComponents: audioUnitComponents,
                                                   componentID: librarySelection,
                                                   graphUnit: auditionNodeID.flatMap { id in
                                                       audioGraph.mesh.node(id: id).flatMap {
                                                           audioGraph.managedAudioUnit(for: $0)
                                                       }
                                                   }) { pluginSize in
                                    // Open at the plug-in's own height (plus headers).
                                    auditionHeight = clampedAuditionHeight(pluginSize.height + 72)
                                }
                            }
                        }
                        .frame(height: clampedAuditionHeight(auditionHeight))
                    }
                }
                .frame(minWidth: 480)
            }
        }
        #if !os(macOS)
        .fileImporter(isPresented: $isImportingProject, allowedContentTypes: [.visuSigProject]) { result in
            switch result {
            case .success(let url): openProject(url)
            case .failure(let error): connectionError = error.localizedDescription
            }
        }
        .fileExporter(isPresented: $isExportingProject, document: exportDocument,
                      contentTypes: [.visuSigProject], defaultFilename: "Music Session") { result in
            exportDocument = nil
            switch result {
            case .success:
                if let pending = openAfterExport {
                    openAfterExport = nil
                    loadProject(pending)
                }
            case .failure(let error):
                openAfterExport = nil
                connectionError = error.localizedDescription
            }
        }
        onCancellation: {
            exportDocument = nil
            openAfterExport = nil
        }
        .confirmationDialog("Save the current session before opening another?",
                            isPresented: $confirmsProjectReplacement, titleVisibility: .visible) {
            Button("Save and Open") {
                openAfterExport = pendingProjectURL
                _ = saveProject()
            }
            Button("Open Without Saving", role: .destructive) {
                if let pendingProjectURL { loadProject(pendingProjectURL) }
            }
            Button("Cancel", role: .cancel) { pendingProjectURL = nil }
        }
        #endif
        .disabled(isOpeningProject)
        .overlay {
            if isOpeningProject {
                ProgressView("Opening project…")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .task(id: projectAction) {
            if let action = projectAction {
                projectAction = nil
                switch action {
                case .open: chooseProject()
                case .save: _ = saveProject()
                case .saveAs: _ = saveProject(saveAs: true)
                }
            }
        }
        .task(id: projectToOpen) {
            if let url = projectToOpen {
                projectToOpen = nil
                // Use an unstructured task so clearing the request does not cancel loading.
                openProject(url)
            }
        }
        .onDisappear { audioGraph.stopSession() }
        .onAppear {
            if let url = audioGraph.audioFileURL {
                audioUnitComponents.setPreviewAudioFile(url: url)
            }
        }
        .onChange(of: librarySelection) { _, selection in
            // Picking an audio effect in the library auditions it.
            if let selection, audioUnitComponents.component(id: selection)?.audioUnitType == .effect {
                showBottom(.audition)
            }
        }
        .onChange(of: canvasState.selectedNodeIDs) { _, selected in
            auditionNodeID = nil
            // Selecting a Mixer node shows its channels.
            if let mixer = selected.first(where: { id in
                audioGraph.mesh.node(id: id).map { audioGraph.role(of: $0) == .mixer } ?? false
            }) {
                shownMixerID = mixer
                showBottom(.mixer)
            } else if selected.count == 1, let id = selected.first,
                      let node = audioGraph.mesh.node(id: id),
                      audioGraph.managedAudioUnit(for: node) != nil {
                auditionNodeID = id
                showBottom(.audition)
            }
        }
    }

    private func saveProject(saveAs: Bool = false) -> Bool {
        guard !isOpeningProject else { return false }
        #if os(macOS)
        var destination = saveAs ? nil : audioGraph.projectURL
        if destination == nil {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.visuSigProject]
            panel.nameFieldStringValue = audioGraph.projectURL?.lastPathComponent ?? "Untitled.visusig"
            panel.canCreateDirectories = true
            guard panel.runModal() == .OK else { return false }
            destination = panel.url
        }
        guard let destination else { return false }
        do {
            try audioGraph.saveProject(to: destination)
            connectionError = nil
            return true
        } catch {
            connectionError = "Couldn't save project: " + error.localizedDescription
            return false
        }
        #else
        do {
            exportDocument = try audioGraph.exportProject()
            isExportingProject = true
        } catch {
            openAfterExport = nil
            connectionError = error.localizedDescription
        }
        return false
        #endif
    }

    private func chooseProject() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.visuSigProject]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { openProject(url) }
        #else
        isImportingProject = true
        #endif
    }

    private func openProject(_ url: URL) {
        guard !isOpeningProject else { return }
        if audioGraph.hasLoadedAudioFile || audioGraph.mesh.nodes.count > 3 || audioGraph.projectURL != nil {
            #if os(macOS)
            let alert = NSAlert()
            alert.messageText = "Save the current music session before opening another?"
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Open Without Saving")
            let response = alert.runModal()
            if response == .alertSecondButtonReturn { return }
            if response == .alertFirstButtonReturn, !saveProject() { return }
            #else
            pendingProjectURL = url
            confirmsProjectReplacement = true
            return
            #endif
        }
        loadProject(url)
    }

    private func loadProject(_ url: URL) {
        guard !isOpeningProject else { return }
        isOpeningProject = true
        Task { @MainActor in
            defer { isOpeningProject = false }
            do {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let loaded = try await AudioGraph.openProject(at: url)
                PluginWindowController.close(nodeIDs: Set(audioGraph.mesh.nodes.map(\.id)))
                audioGraph.stopSession()
                audioUnitComponents.clearPreviewAudioFile()
                audioGraph = loaded
                canvasState = MeshCanvasState()
                auditionNodeID = nil
                shownMixerID = nil
                loaded.activateProject()
                if let url = loaded.audioFileURL {
                    audioUnitComponents.setPreviewAudioFile(url: url)
                }
                connectionError = nil
            } catch {
                connectionError = "Couldn't open project: " + error.localizedDescription
            }
        }
    }

    enum BottomPanel: String, CaseIterable, Identifiable {
        case mixer = "Mixer"
        case audition = "Audition"

        var id: Self { self }
        var systemImage: String { self == .mixer ? "slider.vertical.3" : "headphones" }
    }

    /// The selected mixer, or else the first one in the graph.
    private var mixerToShow: UUID? {
        if let shownMixerID, audioGraph.mesh.node(id: shownMixerID) != nil { return shownMixerID }
        return audioGraph.mesh.nodes.first { audioGraph.role(of: $0) == .mixer }?.id
    }

    private func showBottom(_ panel: BottomPanel) {
        bottomPanel = panel
        showsBottomArea = true
        if panel == .mixer { auditionHeight = max(auditionHeight, 300) }
    }

    private func panelToggle(_ title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Button {
            withAnimation(.snappy) { isOn.wrappedValue.toggle() }
        } label: {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(isOn.wrappedValue ? Color.accentColor : Color.secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isOn.wrappedValue ? "Hide \(title)" : "Show \(title)")
        .accessibilityLabel(title)
        .accessibilityValue(isOn.wrappedValue ? "Shown" : "Hidden")
    }

    /// Canvas coordinates → mesh coordinates, matching MeshCanvas's transform
    /// (origin at the canvas centre, offset by pan, scaled by zoom).
    private func meshPoint(forCanvasLocation location: CGPoint) -> CGPoint {
        CGPoint(x: (location.x - canvasSize.width / 2 - canvasState.pan.width) / canvasState.zoom,
                y: (location.y - canvasSize.height / 2 - canvasState.pan.height) / canvasState.zoom)
    }

    /// The bottom area's height range. The canvas keeps its own minimum
    /// height, so the split view never squeezes it out. (A range measured
    /// from the editor's height came back too small inside the split view.)
    private var auditionHeightRange: ClosedRange<CGFloat> {
        120 ... 640
    }

    private func clampedAuditionHeight(_ height: CGFloat) -> CGFloat {
        min(max(height, auditionHeightRange.lowerBound), auditionHeightRange.upperBound)
    }

    private var visibleCenter: CGPoint {
        meshPoint(forCanvasLocation: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2))
    }

    // MARK: - Canvas

    private var canvas: some View {
        MeshCanvas(mesh: audioGraph.mesh, layout: audioGraph.layout, state: canvasState) { node in
            HStack(spacing: 6) {
                if case .plugin = audioGraph.role(of: node) {
                    Button {
                        audioGraph.togglePluginPower(node.id)
                    } label: {
                        Image(systemName: "power")
                            .foregroundStyle(audioGraph.isPluginEnabled(node) ? Color.green : Color.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help(audioGraph.isPluginEnabled(node) ? "Bypass plug-in" : "Enable plug-in")
                    .accessibilityLabel("Power for " + node.title)
                    .accessibilityValue(audioGraph.isPluginEnabled(node) ? "On" : "Bypassed")
                }
                Label(node.title, systemImage: icon(for: audioGraph.role(of: node)))
                    .opacity(audioGraph.isPluginEnabled(node) ? 1 : 0.5)
            }
        }
        .nodeTint { node in tint(for: audioGraph.role(of: node)) }
        .portTint { port in port.signal == .midi ? .orange : .cyan }
        .edgeTint { edge in
            audioGraph.mesh.port(at: GraphEndpoint(nodeID: edge.sourceNodeID, portID: edge.sourcePortID))?
                .signal == .midi ? .orange : .cyan
        }
        .nodeContextMenu { node in nodeMenu(node) }
        .edgeContextMenu { edge in
            if let signal = audioGraph.signal(for: edge.id) {
                SignalInstrumentMenuItems(payload: signal)
                Divider()
            }
            Button("Delete Wire", role: .destructive) { delete(nodeIDs: [], edgeID: edge.id) }
        }
        .edgeAccessory { edge -> SignalInstrumentPanel? in
            guard let signal = audioGraph.signal(for: edge.id), !signal.instruments.isEmpty else { return nil }
            return SignalInstrumentPanel(payload: signal)
        }
        .canvasContextMenu { location in addMenu(location) }
        .onConnect { source, target in
            do {
                try audioGraph.connect(source: source, target: target)
                connectionError = nil
            } catch MeshConnectionError.incompatibleSignals {
                connectionError = "Audio and MIDI ports can't be connected to each other."
            } catch {
                connectionError = "Can't connect those ports: \(error.localizedDescription)"
            }
        }
        .onConnectionRefused { first, second in
            connectionError = refusalReason(first, second)
        }
        .onDeleteSelection { nodeIDs, edgeID in
            delete(nodeIDs: nodeIDs, edgeID: edgeID)
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { canvasSize = $0 }
        .dropDestination(for: String.self) { payloads, location in
            let components = payloads
                .compactMap(PluginDrag.componentID(from:))
                .compactMap(audioUnitComponents.component(id:))
            guard !components.isEmpty else { return false }
            let point = meshPoint(forCanvasLocation: location)
            for (index, component) in components.enumerated() {
                addPlugin(component, at: CGPoint(x: point.x + CGFloat(index) * 40,
                                                 y: point.y + CGFloat(index) * 40))
            }
            return true
        }
    }

    /// Right-click on empty canvas: add any plug-in kind or a source.
    @ViewBuilder
    private func addMenu(_ location: MeshCanvasLocation) -> some View {
        pluginMenu("Add Instrument", types: [.instrument], location: location)
        pluginMenu("Add MIDI Effect", types: [.midiEffect], location: location)
        pluginMenu("Add Audio Effect", types: [.effect, .musicEffect], location: location)
        Button("Add Mixer", systemImage: "slider.vertical.3") {
            let mixer = audioGraph.addMixer(at: location.meshPoint)
            shownMixerID = mixer.id
        }
        Divider()
        Button("Add MIDI Input", systemImage: "pianokeys") {
            audioGraph.addMIDIInput(at: location.meshPoint)
        }
        Button("Add Audio File Source", systemImage: "waveform") {
            audioGraph.addAudioFileSource(at: location.meshPoint)
        }
        .disabled(audioGraph.hasAudioFileSource)
        Divider()
        Button("Add Generic Payload Node", systemImage: "shippingbox") {
            audioGraph.addGenericNode(at: location.meshPoint)
        }
    }

    /// One submenu per manufacturer, as in Logic's plug-in menus.
    private func pluginMenu(_ title: String, types: [AudioUnitType], location: MeshCanvasLocation) -> some View {
        let components = types.flatMap { audioUnitComponents.components(of: $0) }
        let byMaker = Dictionary(grouping: components, by: \.mfg)
        let makers = byMaker.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        return Menu {
            ForEach(makers, id: \.self) { maker in
                Menu(maker) {
                    ForEach(byMaker[maker, default: []].sorted {
                        $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    }) { component in
                        Button(component.name) { addPlugin(component, at: location.meshPoint) }
                    }
                }
            }
        } label: {
            Label(title, systemImage: types[0].systemImage)
        }
        .disabled(components.isEmpty)
    }

    @ViewBuilder
    private func nodeMenu(_ node: GraphNode<Payload>) -> some View {
        switch audioGraph.role(of: node) {
        case .plugin(let type):
            if let unit = audioGraph.managedAudioUnit(for: node) {
                Button("Open Plug-in", systemImage: "macwindow") {
                    PluginWindowController.open(nodeID: node.id, title: node.title, unit: unit)
                }
            }
            if type.takesMIDI {
                Button("Play Test Note", systemImage: "music.note") { audioGraph.playTestNote(on: node.id) }
            }
            Divider()
            if type.takesAudio {
                Button("Add Audio Input") { audioGraph.addPort(to: node.id, direction: .input, signal: .audio) }
            }
            if type.producesAudio {
                Button("Add Audio Output") { audioGraph.addPort(to: node.id, direction: .output, signal: .audio) }
            }
            Divider()
        case .midiInput:
            Menu("Source") {
                Toggle(AudioGraph.virtualInputName, isOn: Binding(
                    get: { audioGraph.isMIDISource(nil, selectedFor: node) },
                    set: { if $0 { audioGraph.setMIDISource(nil, for: node.id) } }
                ))
                if !audioGraph.midiSources.isEmpty { Divider() }
                ForEach(audioGraph.midiSources, id: \.uniqueID) { source in
                    Toggle(source.displayName, isOn: Binding(
                        get: { audioGraph.isMIDISource(source, selectedFor: node) },
                        set: { if $0 { audioGraph.setMIDISource(source, for: node.id) } }
                    ))
                }
                Divider()
                Button("Refresh Sources") { audioGraph.refreshMIDISources() }
            }
            Divider()
        case .mixer:
            Button("Show Mixer", systemImage: "slider.vertical.3") {
                shownMixerID = node.id
                showBottom(.mixer)
            }
            Divider()
        default:
            EmptyView()
        }
        Button("Delete Node", role: .destructive) { delete(nodeIDs: [node.id], edgeID: nil) }
    }

    /// Why two ports the user tried to join can't be connected.
    private func refusalReason(_ first: GraphEndpoint, _ second: GraphEndpoint) -> String {
        guard let a = audioGraph.mesh.port(at: first), let b = audioGraph.mesh.port(at: second) else {
            return "Those ports can't be connected."
        }
        if !a.carriesSameSignal(as: b) {
            return "Audio and MIDI ports can't be connected to each other."
        }
        if a.direction == b.direction {
            return a.direction == .input
                ? "Both are inputs: connect an output to an input."
                : "Both are outputs: connect an output to an input."
        }
        return "Those ports can't be connected."
    }

    private func icon(for role: AudioNodeRole) -> String {
        switch role {
        case .source: return "waveform"
        case .midiInput: return "pianokeys"
        case .plugin(let type): return type.systemImage
        case .mixer: return "slider.vertical.3"
        case .output: return "speaker.wave.2"
        case .generic: return "shippingbox"
        }
    }

    private func tint(for role: AudioNodeRole) -> Color {
        switch role {
        case .source: return Color(red: 0.18, green: 0.46, blue: 0.90)
        case .midiInput: return Color(red: 0.85, green: 0.47, blue: 0.10)
        case .plugin(.instrument): return Color(red: 0.75, green: 0.30, blue: 0.20)
        case .plugin(.midiEffect): return Color(red: 0.70, green: 0.50, blue: 0.10)
        case .plugin: return Color(red: 0.55, green: 0.22, blue: 0.80)
        case .mixer: return Color(red: 0.25, green: 0.45, blue: 0.55)
        case .output: return Color(red: 0.15, green: 0.65, blue: 0.40)
        case .generic: return Color(red: 0.35, green: 0.35, blue: 0.40)
        }
    }

    private func delete(nodeIDs: Set<UUID>, edgeID: UUID?) {
        var removedEdges = Set(audioGraph.mesh.edges
            .filter { nodeIDs.contains($0.sourceNodeID) || nodeIDs.contains($0.targetNodeID) }
            .map(\.id))
        if let edgeID {
            audioGraph.removeEdge(id: edgeID)
            removedEdges.insert(edgeID)
        }
        if !nodeIDs.isEmpty {
            audioGraph.removeNodes(nodeIDs)
        }
        canvasState.forget(nodeIDs: nodeIDs, edgeIDs: removedEdges)
    }

    /// Instantiates a fresh Audio Unit for the graph. The library's audition
    /// units stay on the preview player.
    private func addPlugin(_ component: Component, at point: CGPoint) {
        component.instantiateComponent { result in
            switch result {
            case .success(let unit?):
                audioGraph.addPlugin(unit, at: point)
                connectionError = nil
            case .success(nil):
                connectionError = "\(component.name) has no instantiable Audio Unit"
            case .failure(let error):
                connectionError = "Couldn't load \(component.name): \(error.localizedDescription)"
            }
        }
    }
}

struct MasterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MasterMenuView()
    }
}
