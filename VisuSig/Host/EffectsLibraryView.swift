//
//  EffectsLibraryView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

/// Drag payload for an effect dragged from the library onto the graph.
enum EffectDrag {
    private static let prefix = "visusig.effect:"

    static func payload(for component: Component) -> String {
        prefix + component.id.uuidString
    }

    static func componentID(from payload: String) -> Component.ID? {
        guard payload.hasPrefix(prefix) else { return nil }
        return UUID(uuidString: String(payload.dropFirst(prefix.count)))
    }
}

/// Logic-style library of installed effect Audio Units, grouped by
/// manufacturer. Select an entry to audition it; drag it onto the graph, or
/// use its context menu, to add it.
struct EffectsLibraryView: View {
    var audioUnitComponents: AudioUnitComponents
    @Binding var selection: Component.ID?
    var onAdd: (Component) -> Void

    @State private var filter = ""

    private var groups: [(manufacturer: String, components: [Component])] {
        let matching = audioUnitComponents.audioUnitComponents.filter {
            filter.isEmpty || $0.nameAndMFG.localizedCaseInsensitiveContains(filter)
        }
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
            HStack {
                Label("Effects", systemImage: "waveform.circle")
                    .font(.headline)
                Spacer()
                Text("\(audioUnitComponents.audioUnitComponents.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            TextField("Filter", text: $filter)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)

            List(selection: $selection) {
                ForEach(groups, id: \.manufacturer) { group in
                    Section(group.manufacturer) {
                        ForEach(group.components) { component in
                            Label(component.name, systemImage: "waveform.circle")
                                .lineLimit(1)
                                .help(component.nameAndMFG)
                                .tag(component.id)
                                .draggable(EffectDrag.payload(for: component)) {
                                    Label(component.name, systemImage: "waveform.circle")
                                        .padding(6)
                                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                                }
                                .contextMenu {
                                    Button("Add to Graph", systemImage: "plus") { onAdd(component) }
                                }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .overlay {
                if audioUnitComponents.audioUnitComponents.isEmpty {
                    ProgressView("Finding effects…")
                } else if groups.isEmpty {
                    ContentUnavailableView.search(text: filter)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Effects library")
    }
}

/// Auditions the library selection on the preview player, using the
/// effect's own interface.
struct EffectAuditionView: View {
    var audioUnitComponents: AudioUnitComponents
    var componentID: Component.ID?

    private var unit: AUManagedUnit? {
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
                Text(audioUnitComponents.hasPreviewAudioFile
                     ? "Preview source: \(audioUnitComponents.previewAudioFileName)"
                     : "Load audio above to audition effects")
                    .font(.caption)
                    .foregroundStyle(audioUnitComponents.hasPreviewAudioFile ? Color.secondary : Color.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Divider()

            if let unit {
                AUComponentView(auManagedUnit: unit, audioUnitComponents: audioUnitComponents)
                    .id(unit.id)
                    .task(id: unit.id) {
                        unit.loadAudioUnitViewController { controller in
                            unit.setController(controller: controller)
                        }
                    }
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
