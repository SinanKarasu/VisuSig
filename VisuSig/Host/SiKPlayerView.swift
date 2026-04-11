//
//  SiKPlayerView.swift
//  VisuSig
//

import SwiftUI
import UniformTypeIdentifiers

struct SiKPlayerView: View {
    var audioGraph: AudioGraph

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
            .help(audioGraph.isPlaying ? "Pause" : "Play")

            // ── File info ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 2) {
                Text(audioGraph.audioFileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(audioGraph.isPlaying ? "Playing" : "Stopped")
                    .font(.system(size: 10))
                    .foregroundStyle(audioGraph.isPlaying ? Color.green : Color.gray)
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
            audioGraph.loadAudioFile(url: url)
        }
    }
}
