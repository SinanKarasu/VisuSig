//
//  EffectsLibraryView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

/// Drag payload for a plug-in dragged from the library onto the graph.
enum PluginDrag {
    private static let prefix = "visusig.plugin:"

    static func payload(for component: Component) -> String {
        prefix + component.id.uuidString
    }

    static func componentID(from payload: String) -> Component.ID? {
        guard payload.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(payload.dropFirst(prefix.count)))
    }
}

/// Logic's library categories.
enum PluginCategory: String, CaseIterable, Identifiable {
    case instruments = "Instruments"
    case midiEffects = "MIDI FX"
    case audioEffects = "Audio FX"

    var id: Self { self }

    /// Audio FX includes effects that can also be played from MIDI.
    var types: [AudioUnitType] {
        switch self {
        case .instruments: return [.instrument]
        case .midiEffects: return [.midiEffect]
        case .audioEffects: return [.effect, .musicEffect]
        }
    }
}

/// Logic-style library of installed Audio Units by category and
/// manufacturer. Select an audio effect to audition it; drag any entry onto
/// the graph, or use its context menu, to add it.
struct PluginLibraryView: View {
    var audioUnitComponents: AudioUnitComponents
    @Binding var selection: Component.ID?
    var onAdd: (Component) -> Void

    @State private var category: PluginCategory = .audioEffects
    @State private var filter = ""

    private var all: [Component] {
        category.types.flatMap { audioUnitComponents.components(of: $0) }
    }

    private var groups: [(manufacturer: String, components: [Component])] {
        let matching = all.filter { filter.isEmpty || $0.nameAndMFG.localizedCaseInsensitiveContains(filter) }
        let grouped = Dictionary(grouping: matching, by: \.mfg)
        return grouped.keys
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { key in
                (key, grouped[key, default: []].sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                })
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $category) {
                ForEach(PluginCategory.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 10)
            .padding(.top, 8)

            HStack {
                TextField("Filter", text: $filter)
                    .textFieldStyle(.roundedBorder)
                Text("\(all.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            List(selection: $selection) {
                ForEach(groups, id: \.manufacturer) { group in
                    Section(group.manufacturer) {
                        ForEach(group.components) { component in
                            row(component)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            // Double-click or Return adds the plug-in, as in Logic's library.
            .contextMenu(forSelectionType: Component.ID.self) { ids in
                Button("Add to Graph", systemImage: "plus") { add(ids) }
            } primaryAction: { ids in
                add(ids)
            }
            .overlay {
                if all.isEmpty {
                    ProgressView("Finding plug-ins…")
                } else if groups.isEmpty {
                    ContentUnavailableView.search(text: filter)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Plug-in library")
    }

    private func add(_ ids: Set<Component.ID>) {
        for id in ids {
            if let component = audioUnitComponents.component(id: id) { onAdd(component) }
        }
    }

    private func row(_ component: Component) -> some View {
        HStack(spacing: 6) {
            Label(component.name, systemImage: component.audioUnitType.systemImage)
                .lineLimit(1)
            if component.audioUnitType == .musicEffect {
                Text("MIDI")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 4)
                    .background(Color.orange.opacity(0.25), in: Capsule())
                    .help("Can also be played from MIDI")
            }
        }
        .help(component.nameAndMFG)
        .tag(component.id)
        .draggable(PluginDrag.payload(for: component)) {
            Label(component.name, systemImage: component.audioUnitType.systemImage)
                .padding(6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

/// Shows a graph plug-in's live controls or auditions a library effect
/// on the preview player.
struct EffectAuditionView: View {
    var audioUnitComponents: AudioUnitComponents
    var componentID: Component.ID?
    var graphUnit: AUManagedUnit? = nil
    /// Reports the loaded plug-in's preferred interface size.
    var onPluginSize: (CGSize) -> Void = { _ in }

    private var unit: AUManagedUnit? {
        if let graphUnit { return graphUnit }
        guard let componentID else { return nil }
        return audioUnitComponents.auManagedEffectUnits
            .compactMap { $0 }
            .first { $0.protoType?.id == componentID }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(unit?.name ?? "Audition", systemImage: "headphones")
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(graphUnit != nil
                     ? "Live graph instance"
                     : audioUnitComponents.hasPreviewAudioFile
                         ? "Preview source: \(audioUnitComponents.previewAudioFileName)"
                         : "Load audio above to audition effects")
                    .font(.caption)
                    .foregroundStyle(graphUnit != nil || audioUnitComponents.hasPreviewAudioFile ? Color.secondary : Color.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            if let unit, let audioUnit = unit.audioUnit {
                PluginInterfaceView(audioUnit: audioUnit, onSizeResolved: onPluginSize)
                    .id(unit.id)
                    .task(id: unit.id) {
                        guard graphUnit == nil else { return }
                        // Route the preview player through this library effect.
                        audioUnitComponents.connectComponent(auManagedUnit: unit) { _ in }
                    }
            } else if let componentID, let component = audioUnitComponents.component(id: componentID),
                      component.audioUnitType != .effect {
                ContentUnavailableView(
                    "Try it on the graph",
                    systemImage: component.audioUnitType.systemImage,
                    description: Text("\(component.audioUnitType.singularName)s are auditioned on the graph: add one, wire it to Output, and play a test note or MIDI.")
                )
            } else if componentID != nil {
                ProgressView("Preparing preview…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "No effect selected",
                    systemImage: "waveform.circle",
                    description: Text("Select an effect in the library to audition it. Drag it onto the graph to add it.")
                )
            }
        }
    }
}

/// A horizontal divider that resizes the view below it by dragging.
struct ResizeHandle: View {
    @Binding var height: CGFloat
    var range: ClosedRange<CGFloat>

    @State private var dragStart: CGFloat?

    var body: some View {
        Rectangle()
            .fill(PlatformUI.separator)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onHover { inside in
                #if os(macOS)
                if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
                #endif
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        let start = dragStart ?? height
                        dragStart = start
                        height = min(max(start - value.translation.height, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in dragStart = nil }
            )
            .accessibilityLabel("Resize audition area")
    }
}
