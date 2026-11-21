//
//  MixerView.swift
//  VisuSig
//

import SwiftUI
import VisualMesh

/// Logic-style channel strips for one Mixer node. Each wire into the mixer
/// is a channel; its settings are the wire's payload, so they are saved with
/// the graph and apply to the engine immediately.
struct MixerView: View {
    var audioGraph: AudioGraph
    var mixerID: UUID?

    var body: some View {
        if let mixerID, let mixer = audioGraph.mesh.node(id: mixerID) {
            let channels = audioGraph.channels(of: mixerID)
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 6) {
                    if channels.isEmpty {
                        Text("Wire sources or instruments into \(mixer.title) to get channels.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal, 20)
                    }
                    ForEach(channels) { edge in
                        ChannelStrip(
                            title: audioGraph.mesh.node(id: edge.sourceNodeID)?.title ?? "?",
                            settings: edge.payload,
                            signal: audioGraph.signal(for: edge.id)
                        ) { change in
                            audioGraph.updateChannel(edge.id, change)
                        }
                    }
                    Divider()
                    MasterStrip(audioGraph: audioGraph)
                }
                .padding(8)
                .frame(maxHeight: .infinity)
            }
            .scrollIndicators(.automatic)
        } else {
            ContentUnavailableView(
                "No mixer",
                systemImage: "slider.vertical.3",
                description: Text("Right-click the canvas and choose Add Mixer.")
            )
        }
    }
}

/// Decibel helpers for faders and meters.
enum Decibels {
    static let floor: Double = -60

    static func from(linear: Double) -> Double {
        linear <= 0 ? floor : max(floor, 20 * log10(linear))
    }

    static func toLinear(_ db: Double) -> Double {
        db <= floor + 0.5 ? 0 : pow(10, db / 20)
    }

    static func label(_ db: Double) -> String {
        db <= floor + 0.5 ? "-∞" : String(format: "%.1f", db)
    }
}

private struct ChannelStrip: View {
    let title: String
    let settings: AudioConnection
    let signal: SignalEdgePayload?
    let update: ((inout AudioConnection) -> Void) -> Void

    private var faderDB: Binding<Double> {
        Binding(
            get: { Decibels.from(linear: Double(settings.volume)) },
            set: { db in update { $0.volume = Float(Decibels.toLinear(db)) } }
        )
    }

    private var pan: Binding<Double> {
        Binding(get: { Double(settings.pan) }, set: { value in update { $0.pan = Float(value) } })
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 84, height: 28)
                .help(title)

            Slider(value: pan, in: -1 ... 1)
                .controlSize(.mini)
                .frame(width: 64)
                .help("Pan")
            Text(panLabel)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 8) {
                LevelMeter(level: signal?.latestTelemetry?.voltage ?? 0)
                VerticalFader(value: faderDB, range: Decibels.floor ... 0)
            }
            // The fader takes whatever height the mixer area has.
            .frame(minHeight: 50, maxHeight: .infinity)

            Text(Decibels.label(faderDB.wrappedValue))
                .font(.caption2.monospacedDigit())

            HStack(spacing: 4) {
                StripToggle(title: "M", isOn: settings.isMuted, tint: .blue) { update { $0.isMuted.toggle() } }
                    .help("Mute")
                StripToggle(title: "S", isOn: settings.isSoloed, tint: .yellow) { update { $0.isSoloed.toggle() } }
                    .help("Solo")
            }
        }
        .padding(8)
        .frame(width: 100)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) channel")
    }

    private var panLabel: String {
        let percent = Int((settings.pan * 100).rounded())
        if percent == 0 { return "C" }
        return percent < 0 ? "L\(-percent)" : "R\(percent)"
    }
}

private struct MasterStrip: View {
    var audioGraph: AudioGraph

    private var faderDB: Binding<Double> {
        Binding(
            get: { Decibels.from(linear: Double(audioGraph.masterVolume)) },
            set: { audioGraph.masterVolume = Float(Decibels.toLinear($0)) }
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            Label("Output", systemImage: "speaker.wave.2")
                .font(.caption.weight(.semibold))
                .frame(height: 30)
            VerticalFader(value: faderDB, range: Decibels.floor ... 0)
                .frame(minHeight: 50, maxHeight: .infinity)
            Text(Decibels.label(faderDB.wrappedValue))
                .font(.caption2.monospacedDigit())
        }
        .padding(8)
        .frame(width: 100)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Output master")
    }
}

/// A standard slider turned upright.
private struct VerticalFader: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            Slider(value: $value, in: range)
                .controlSize(.small)
                .frame(width: proxy.size.height)
                .rotationEffect(.degrees(-90))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(width: 24)
        .accessibilityLabel("Volume")
    }
}

/// RMS level from the wire's telemetry, in decibels.
private struct LevelMeter: View {
    let level: Double

    var body: some View {
        let fraction = (Decibels.from(linear: level) - Decibels.floor) / -Decibels.floor
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2).fill(Color.black.opacity(0.4))
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [.green, .yellow, .red], startPoint: .bottom, endPoint: .top))
                    .frame(height: proxy.size.height * max(0, min(1, fraction)))
            }
        }
        .frame(width: 8)
        .animation(.linear(duration: 0.05), value: level)
        .accessibilityHidden(true)
    }
}

private struct StripToggle: View {
    let title: String
    let isOn: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .frame(width: 26, height: 20)
                .foregroundStyle(isOn ? Color.black : Color.primary)
                .background(isOn ? tint : Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
