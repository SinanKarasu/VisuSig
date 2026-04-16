//
//  SiKPlayerView.swift
//  VisuSig
//

import SwiftUI
import UniformTypeIdentifiers

struct SiKPlayerView: View {
    var audioGraph: AudioGraph
    var onAudioFileLoaded: (URL) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 16) {
            // ── Play / Pause ──────────────────────────────────────────
            Button {
                _ = audioGraph.togglePlay()
            } label: {
                Image(systemName: audioGraph.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(audioGraph.isPlaying ? Color.yellow : Color.green)
            }
            .buttonStyle(.plain)
            .disabled(!audioGraph.canTogglePlayback)
            .help(playbackHelpText)

            // ── File info ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 2) {
                Text(audioGraph.audioFileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(audioGraph.hasLoadedAudioFile ? Color.white : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(statusColor)
            }

            Spacer()

            // ── Load audio file ───────────────────────────────────────
            Button {
                openFilePicker()
            } label: {
                Label("Load Audio…", systemImage: "folder.badge.plus")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .help("Load an audio file into the Source node")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    private var statusText: String {
        if audioGraph.isPlaying {
            return "Playing"
        }
        if !audioGraph.hasLoadedAudioFile {
            return "Load a file to begin"
        }
        return audioGraph.hasPlayableRoute ? "Ready" : "Wire Audio Source to Output"
    }

    private var statusColor: Color {
        if audioGraph.isPlaying {
            return .green
        }
        return (audioGraph.hasLoadedAudioFile && audioGraph.hasPlayableRoute) ? .gray : .orange
    }

    private var playbackHelpText: String {
        if audioGraph.isPlaying {
            return "Pause"
        }
        if !audioGraph.hasLoadedAudioFile {
            return "Load an audio file first"
        }
        if !audioGraph.hasPlayableRoute {
            return "Wire Audio Source to Output first"
        }
        return "Play"
    }

    // MARK: - File picker

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.title = "Choose an Audio File"
        panel.allowedContentTypes = [
            UTType.audio,
            UTType(filenameExtension: "aif") ?? .audio,
            UTType(filenameExtension: "aiff") ?? .audio,
            UTType(filenameExtension: "wav") ?? .audio,
            UTType(filenameExtension: "mp3") ?? .audio,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "caf") ?? .audio,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if audioGraph.loadAudioFile(url: url) {
                onAudioFileLoaded(url)
            }
        }
    }
}
