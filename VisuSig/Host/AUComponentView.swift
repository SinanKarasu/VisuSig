//
//  AUComponentView.swift
//  SiKAUv3Host
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct AUComponentView: View {
    @ObservedObject var auManagedUnit: AUManagedUnit
    var audioUnitComponents: AudioUnitComponents
	@State var result : Result<AUManagedUnit?, any Error>? = nil
    // change this to be the persistent one.
    init(auManagedUnit: AUManagedUnit, audioUnitComponents: AudioUnitComponents ) {
        self.auManagedUnit = auManagedUnit
        self.audioUnitComponents = audioUnitComponents
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
						VStack {
							makeView(size: reader.size)
								.onAppear {
									audioUnitComponents.connectComponent(auManagedUnit: auManagedUnit) { result in
										print("Got result:\(result)")
										self.result = result
									}
								}
							if let result = result {
								Text("Got result:\(result)")
							}
						}
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
