import AVFoundation
import CoreAudioKit
import SwiftMIDICore
import SwiftMIDIIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
private final class MIDIMixSession {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let instrumentGain = AVAudioMixerNode()
    private let midi = MIDIManager(clientName: "VisuSig", model: "VisuSig", manufacturer: "VisuSig")
    private(set) var unit: AVAudioUnit?
    private var file: AVAudioFile?
    private var scopedURL: URL?
    private var runID = UUID()
    private var playbackID = UUID()
    private var testNote: Task<Void, Never>?

    private(set) var instruments: [AVAudioUnitComponent] = []
    private(set) var sources: [MIDIOutputEndpoint] = []
    private(set) var fileName: String?
    private(set) var isStarting = false
    private(set) var isRunning = false
    private(set) var isPlayingAudio = false
    private(set) var eventCount = 0
    private(set) var instrumentIndex = 0
    var selectedInstrument: AVAudioUnitComponent? {
        instruments.indices.contains(instrumentIndex) ? instruments[instrumentIndex] : nil
    }
    private(set) var sourceID: MIDIIdentifier?

    func selectSource(_ sourceID: MIDIIdentifier?) {
        guard sourceID != self.sourceID else { return }
        if isRunning {
            let connection = midi.managedInputConnections["keyboard-input"]
            connection?.removeAllOutputs()
            if let schedule = unit?.auAudioUnit.scheduleMIDIEventBlock {
                for channel in UInt8(0)..<16 {
                    Self.send([0xB0 | channel, 64, 0], using: schedule)
                    Self.send([0xB0 | channel, 120, 0], using: schedule)
                    Self.send([0xB0 | channel, 123, 0], using: schedule)
                }
            }
            if let sourceID {
                connection?.add(outputs: [MIDIEndpointIdentity.uniqueID(sourceID)])
            }
        }
        self.sourceID = sourceID
    }
    var errorMessage: String?
    var instrumentLevel: Float = 0.75 {
        didSet { instrumentGain.outputVolume = instrumentLevel }
    }
    var audioLevel: Float = 0.5 {
        didSet { player.volume = audioLevel }
    }
    var mixLevel: Float = 0.75 {
        didSet { engine.mainMixerNode.outputVolume = mixLevel }
    }

    init() {
        engine.attach(player)
        engine.attach(instrumentGain)
        instrumentGain.outputVolume = instrumentLevel
        player.volume = audioLevel
        engine.mainMixerNode.outputVolume = mixLevel
    }

    func discover() {
        let description = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice, componentSubType: 0,
            componentManufacturer: 0, componentFlags: 0, componentFlagsMask: 0
        )
        let components = AVAudioUnitComponentManager.shared().components(matching: description)
        instruments = components.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        #if os(macOS)
        let defaultInstrument = kAudioUnitSubType_DLSSynth
        #else
        let defaultInstrument = kAudioUnitSubType_Sampler
        #endif
        instrumentIndex = instruments.firstIndex {
            $0.audioComponentDescription.componentSubType == defaultInstrument
                && $0.audioComponentDescription.componentManufacturer == kAudioUnitManufacturer_Apple
        } ?? 0
        refreshMIDI()
    }

    func refreshMIDI() {
        do {
            try midi.start()
            sources = midi.endpoints.outputs
            if let sourceID, !sources.contains(where: { $0.uniqueID == sourceID }) {
                selectSource(nil)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadAudio(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        do {
            let loaded = try AVAudioFile(forReading: url)
            stopAudio()
            scopedURL?.stopAccessingSecurityScopedResource()
            scopedURL = scoped ? url : nil
            file = loaded
            fileName = url.lastPathComponent
            errorMessage = nil
            if isRunning { connectAudioFile(loaded) }
        } catch {
            if scoped { url.stopAccessingSecurityScopedResource() }
            errorMessage = error.localizedDescription
        }
    }

    func selectInstrument(_ index: Int) {
        guard !isStarting, index != instrumentIndex, instruments.indices.contains(index) else { return }
        let shouldRestart = isRunning
        if shouldRestart { stop() }
        instrumentIndex = index
        errorMessage = nil
        if shouldRestart { start() }
    }

    func start() {
        guard !isRunning, !isStarting, let selectedInstrument else { return }
        isStarting = true
        errorMessage = nil
        eventCount = 0
        let id = UUID()
        runID = id
        let description = selectedInstrument.audioComponentDescription
        Task {
            await startInstrument(description, runID: id)
        }
    }

    private func startInstrument(_ description: AudioComponentDescription, runID id: UUID) async {
        guard runID == id else { return }
        do {
            let instrument = try await AVAudioUnit.instantiate(with: description, options: [])
            guard runID == id else { return }
            guard instrument.auAudioUnit.scheduleMIDIEventBlock != nil else {
                throw SessionError.noMIDIInput
            }

            engine.attach(instrument)
            unit = instrument
            engine.connect(instrument, to: instrumentGain, format: nil)
            engine.connect(instrumentGain, to: engine.mainMixerNode, format: nil)
            if let file { connectAudioFile(file) }
            engine.prepare()
            try PlatformAudioSession.activate()
            try engine.start()

            try midi.start()
            let receiver = MIDIReceiver.events(options: [.filterActiveSensingAndClock]) {
                [weak self] events, _, _ in
                let messages = events.map { $0.midi1RawBytes() }
                DispatchQueue.main.async {
                    guard let self, self.runID == id, self.isRunning else { return }
                    for message in messages { self.schedule(message) }
                }
            }
            try midi.addInput(name: "VisuSig MIDI In", tag: "virtual-input",
                              uniqueID: .userDefaultsManaged(key: "visusig.midi.input"), receiver: receiver)
            try midi.addInputConnection(
                to: .outputs(matching: sourceID.map { [.uniqueID($0)] } ?? []),
                tag: "keyboard-input", receiver: receiver
            )
            isStarting = false
            isRunning = true
        } catch {
            guard runID == id else { return }
            stop()
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        runID = UUID()
        isStarting = false
        isRunning = false
        testNote?.cancel()
        testNote = nil
        midi.removeAll()
        if let schedule = unit?.auAudioUnit.scheduleMIDIEventBlock {
            for channel in UInt8(0)..<16 {
                Self.send([0xB0 | channel, 120, 0], using: schedule)
                Self.send([0xB0 | channel, 123, 0], using: schedule)
            }
        }
        stopAudio()
        engine.stop()
        engine.disconnectNodeOutput(instrumentGain)
        engine.disconnectNodeOutput(player)
        if let unit { engine.detach(unit) }
        unit = nil
        engine.reset()
    }

    func close() {
        stop()
        file = nil
        fileName = nil
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
    }

    private func connectAudioFile(_ file: AVAudioFile) {
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
    }

    func toggleAudio() {
        guard isRunning, let file else { return }
        if isPlayingAudio {
            stopAudio()
            return
        }
        let id = UUID()
        playbackID = id
        isPlayingAudio = true
        player.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.playbackID == id else { return }
                self.stopAudio()
            }
        }
        player.play()
    }

    private func stopAudio() {
        playbackID = UUID()
        player.stop()
        isPlayingAudio = false
    }

    func playTestNote() {
        guard isRunning, testNote == nil else { return }
        schedule([0x90, 60, 88])
        testNote = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            schedule([0x80, 60, 0])
            testNote = nil
        }
    }

    private func schedule(_ message: [UInt8]) {
        guard let status = message.first, (0x80...0xEF).contains(status),
              let schedule = unit?.auAudioUnit.scheduleMIDIEventBlock else { return }
        Self.send(message, using: schedule)
        eventCount += 1
    }

    private static func send(_ message: [UInt8], using schedule: AUScheduleMIDIEventBlock) {
        message.withUnsafeBufferPointer { bytes in
            guard let start = bytes.baseAddress else { return }
            schedule(AUEventSampleTimeImmediate, 0, bytes.count, start)
        }
    }

    private enum SessionError: LocalizedError {
        case noMIDIInput

        var errorDescription: String? { "The selected Audio Unit cannot receive MIDI." }
    }
}

struct MIDIWorkspace: View {
    @State private var session = MIDIMixSession()
    @State private var isChoosingAudio = false

    var body: some View {
        @Bindable var session = session

        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("MIDI & Audio").font(.title2.weight(.semibold))
                Spacer()
                if session.isStarting { ProgressView().controlSize(.small) }
                if session.isRunning {
                    Button("Stop", systemImage: "stop.fill") { session.stop() }
                } else {
                    Button("Start MIDI", systemImage: "play.fill") {
                        session.start()
                    }
                    .disabled(session.isStarting || session.instruments.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 14) {
                GridRow {
                    GroupBox("MIDI Input") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Source", selection: Binding(
                                get: { session.sourceID },
                                set: { session.selectSource($0) }
                            )) {
                                Text("Virtual input only").tag(nil as MIDIIdentifier?)
                                ForEach(session.sources, id: \.uniqueID) { source in
                                    Text(source.displayName).tag(Optional(source.uniqueID))
                                }
                            }
                            Button("Refresh Sources") { session.refreshMIDI() }
                            if session.isRunning {
                                Text("Virtual destination: VisuSig MIDI In")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(session.isStarting)
                    }
                    arrow("MIDI")
                    GroupBox("Software Instrument") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.selectedInstrument?.name ?? "No instrument selected")
                                .lineLimit(1)
                            Button("Test Note") { session.playTestNote() }
                                .disabled(!session.isRunning)
                        }
                    }
                    arrow("Audio")
                    GroupBox("Mixer") {
                        VStack(alignment: .leading, spacing: 8) {
                            Slider(value: $session.instrumentLevel, in: 0...1) { Text("Instrument") }
                            Slider(value: $session.audioLevel, in: 0...1) { Text("Audio file") }
                            Slider(value: $session.mixLevel, in: 0...1) { Text("Output") }
                        }
                        .frame(minWidth: 190)
                    }
                    arrow("Audio")
                    Label("Output", systemImage: "speaker.wave.2")
                }
                GridRow {
                    GroupBox("Audio File") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.fileName ?? "No file selected")
                                .lineLimit(1)
                                .truncationMode(.middle)
                            HStack {
                                Button("Open Audio…") { isChoosingAudio = true }
                                Button(session.isPlayingAudio ? "Stop Audio" : "Play Audio") {
                                    session.toggleAudio()
                                }
                                .disabled(!session.isRunning || session.fileName == nil)
                            }
                        }
                    }
                    .gridCellColumns(3)
                    arrow("Audio")
                    Label("To Mixer", systemImage: "slider.horizontal.3")
                }
            }

            if let error = session.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
            }
            if session.isRunning {
                Text("\(session.eventCount) MIDI messages sent to the instrument")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    .accessibilityIdentifier("midi-message-count")
            }
            instrumentBrowser
        }
        .padding(20)
        .onAppear { session.discover() }
        .onDisappear { session.close() }
        .fileImporter(isPresented: $isChoosingAudio, allowedContentTypes: UTType.sampledAudioFileTypes) { result in
            switch result {
            case .success(let url): session.loadAudio(url)
            case .failure(let error): session.errorMessage = error.localizedDescription
            }
        }
    }

    private var instrumentBrowser: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instruments").font(.headline)
            WorkspaceSplitView {
                if session.instruments.isEmpty {
                    Text("No software instruments found")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 240, maxWidth: 340, maxHeight: .infinity)
                } else {
                    List(selection: Binding<Int?>(
                        get: { session.instrumentIndex },
                        set: { if let index = $0 { session.selectInstrument(index) } }
                    )) {
                        ForEach(session.instruments.indices, id: \.self) { index in
                            let instrument = session.instruments[index]
                            Label {
                                VStack(alignment: .leading) {
                                    Text(instrument.name)
                                    Text(instrument.manufacturerName)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "pianokeys")
                            }
                            .tag(index)
                        }
                    }
                    .accessibilityLabel("Software instruments")
                    .disabled(session.isStarting)
                    .frame(minWidth: 240, idealWidth: 280, maxWidth: 340)
                }

                if let unit = session.unit, session.isRunning {
                    InstrumentEditor(unit: unit.auAudioUnit)
                        .id(ObjectIdentifier(unit))
                        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                } else if let instrument = session.selectedInstrument {
                    ContentUnavailableView(
                        instrument.name, systemImage: "pianokeys",
                        description: Text("Start MIDI to open the instrument controls.")
                    )
                    .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color.clear.frame(minWidth: 400, maxWidth: .infinity)
                }
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxHeight: .infinity)
    }

    private func arrow(_ signal: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: "arrow.right")
            Text(signal).font(.caption2)
        }
        .foregroundStyle(.secondary)
    }
}

private struct InstrumentEditor: View {
    let unit: AUAudioUnit

    var body: some View {
        PluginInterfaceView(audioUnit: unit)
    }
}
