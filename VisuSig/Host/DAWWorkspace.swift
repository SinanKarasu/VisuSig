import SwiftUI

/// The DAW routing layout is retained while other workspaces are visible.
struct DAWWorkspace: View {
    private enum SourceKind: String, CaseIterable, Identifiable {
        case audioFile = "Audio File"
        case microphone = "Microphone"
        case midiInput = "MIDI Input"
        case midiFile = "MIDI File"

        var id: Self { self }
        var isMIDI: Bool { self == .midiInput || self == .midiFile }
        var icon: String {
            switch self {
            case .audioFile: return "waveform"
            case .microphone: return "mic"
            case .midiInput: return "pianokeys"
            case .midiFile: return "music.note.list"
            }
        }
    }

    private struct Source: Identifiable {
        let id = UUID()
        let kind: SourceKind
        var name: String
    }

    @State private var sources: [Source] = [
        Source(kind: .audioFile, name: "Audio File"),
        Source(kind: .microphone, name: "Microphone"),
        Source(kind: .midiInput, name: "MIDI Keyboard")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("DAW").font(.title2.weight(.semibold))
                Spacer()
                Menu {
                    ForEach(SourceKind.allCases) { kind in
                        Button(kind.rawValue, systemImage: kind.icon) {
                            sources.append(Source(kind: kind, name: kind.rawValue))
                        }
                    }
                } label: {
                    Label("Add Source", systemImage: "plus")
                }
            }

            Text("Routing layout · Audio and MIDI engine connections are under development.")
                .font(.callout)
                .foregroundStyle(.secondary)

            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 24) {
                        ForEach($sources) { $source in
                            VStack(spacing: 0) {
                                sourceCard(source: $source)
                                    .frame(height: 112)
                                if source.kind.isMIDI {
                                    connection("MIDI", color: .orange)
                                    Label("Software Instrument", systemImage: "pianokeys")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 62)
                                        .background(.background, in: RoundedRectangle(cornerRadius: 10))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.orange.opacity(0.4))
                                        }
                                } else {
                                    Color.clear.frame(height: 110)
                                }
                                connection("Audio", color: .blue)
                            }
                            .frame(width: 220)
                        }
                    }

                    if sources.isEmpty {
                        ContentUnavailableView(
                            "Add an audio or MIDI source",
                            systemImage: "point.3.connected.trianglepath.dotted"
                        )
                        .frame(height: 270)
                    } else {
                        Rectangle()
                            .fill(.blue.opacity(0.6))
                            .frame(height: 2)
                        connection(nil, color: .blue)
                    }

                    VStack(spacing: 12) {
                        Label("Mixer", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        if !sources.isEmpty {
                            HStack(spacing: 24) {
                                ForEach(sources) { source in
                                    Label(source.name, systemImage: source.kind.icon)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 196)
                                        .padding(12)
                                        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12).stroke(.blue.opacity(0.4))
                    }

                    connection("Audio", color: .blue)
                    Label("Audio Output", systemImage: "speaker.wave.2")
                        .font(.headline)
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
    }

    private func sourceCard(source: Binding<Source>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(source.wrappedValue.kind.rawValue, systemImage: source.wrappedValue.kind.icon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    sources.removeAll { $0.id == source.wrappedValue.id }
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help("Remove source")
            }
            TextField("Source name", text: source.name)
                .textFieldStyle(.roundedBorder)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(source.wrappedValue.kind.isMIDI ? .orange.opacity(0.4) : .blue.opacity(0.4))
        }
    }

    private func connection(_ label: String?, color: Color) -> some View {
        VStack(spacing: 2) {
            Rectangle().fill(color.opacity(0.6)).frame(width: 2, height: 16)
            if let label {
                Text(label).font(.caption2).foregroundStyle(color)
            }
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8))
                .foregroundStyle(color)
        }
        .frame(height: 48)
    }
}
