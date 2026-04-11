//
//  MasterMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/8/22.
//

import SwiftUI

struct MyBorder: View {
    let color: Color
    var body: some View {
        Rectangle()
            .stroke(color, lineWidth: 5)
    }
}

struct MasterMenuView: View {
    @State var audioUnitComponents = AudioUnitComponents()

    /// The visual mesh IS the AudioGraph — one object drives both the node canvas and the audio engine.
    @State var audioGraph: AudioGraph = Mesh.sampleMesh() as! AudioGraph

    var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {

                // ── Transport bar ──────────────────────────────────────
                SiKPlayerView(audioGraph: audioGraph)
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
        }
    }
}

struct MasterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MasterMenuView()
    }
}
