//
//  AUComponent3View.swift
//  SiKAUv3Host
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct AUComponent3View: View {
    @ObservedObject var auManagedUnit: AUManagedUnit
    var audioUnitComponents: AudioUnitComponents
    // change this to be the persistent one.
    init(auManagedUnit: AUManagedUnit, audioUnitComponents: AudioUnitComponents ) {
        self.auManagedUnit = auManagedUnit
        self.audioUnitComponents = audioUnitComponents
        audioUnitComponents.connectComponent(auManagedUnit: auManagedUnit) { result in
            print("Got result\(result)")
        }

    }
    
    func loadAudioUnitViewController(completion: @escaping (NSViewController?) -> Void) {
        if let audioUnit = auManagedUnit.audioUnit {
            audioUnit.requestViewController { viewController in
                DispatchQueue.main.async {
                    completion(viewController)
                }
            }
        }
    }

    var body: some View {
        return GeometryReader { reader in
            VStack {
                Button(action: {
                    self.auManagedUnit.toggleViewMode()

                }) {
                    Image(systemName: "location.viewfinder")
                        .imageScale(.large)
                        .frame(width: 64, height: 64)
                }


                Rectangle().fill(Color.green).opacity(0.2)
                    .overlay(
                        makeView(size: reader.size)
                    )
            }
        }
    }
    
    func makeView(size: CGSize) -> some View {
        AUComponentControllerView(
                                           componentViewController: auManagedUnit.componentViewController,
                                           size: size
        )
    }
    
}

