//
//  TopComponentMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI

struct TopComponentMenuView: View {
    var audioUnitComponents: AudioUnitComponents

    var body: some View {
        audioUnitComponents.initializeEffects(instantiate: false)
        return ScrollView([.horizontal]) {
            HStack(alignment: .bottom, spacing: 70) {
                ForEach(audioUnitComponents.audioUnitComponents, id: \.self) { item in
                    Button { } label: {
                        componentIcon(component: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: 100, maxHeight: 100)
                }
            }
        }
    }

    func componentIcon(component: Component) -> some View {
        ZStack {
            Image(systemName: "waveform.and.mic")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
            Text(component.nameAndMFG)
        }
    }
}

struct TopComponentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopComponentMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
