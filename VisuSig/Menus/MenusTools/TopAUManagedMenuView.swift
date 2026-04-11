//
//  TopAUManagedMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI

struct TopAUManagedMenuView: View {
    var audioUnitComponents: AudioUnitComponents

    var body: some View {
        ScrollView([.horizontal]) {
            HStack(alignment: .bottom, spacing: 70) {
                ForEach(audioUnitComponents.auManagedEffectUnits, id: \.self) { item in
                    Button { } label: {
                        componentIcon(auManagedUnit: item!)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: 100, maxHeight: 100)
                }
            }
        }
    }

    func componentIcon(auManagedUnit: AUManagedUnit) -> some View {
        ZStack {
            Image(systemName: "waveform.and.mic")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
            Text(auManagedUnit.name)
        }
    }
}

struct TopAUManagedMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopAUManagedMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
