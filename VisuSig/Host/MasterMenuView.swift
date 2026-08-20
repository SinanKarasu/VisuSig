//
//  MasterMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/8/22.
//

import SwiftUI

struct MasterMenuView: View {
    enum Workspace: String, CaseIterable, Identifiable {
        case payload = "Payload"
        case audioUnits = "Audio Units"

        var id: Self { self }
    }

    @State private var workspace: Workspace = .payload

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
                .frame(width: 280)
                Spacer()
                Text(workspace == .payload
                     ? "Payloads are durable; runtimes are adapters."
                     : "Apple Audio Units through the Payload adapter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(.bar)

            switch workspace {
            case .payload:
                PayloadWorkbenchView()
            case .audioUnits:
                AudioUnitWorkspaceView()
            }
        }
        .frame(minWidth: 1100, minHeight: 720)
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
