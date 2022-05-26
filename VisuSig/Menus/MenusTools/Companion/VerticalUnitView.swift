//
//  WitnessesView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/25/22.
//

import SwiftUI


struct VerticalUnitView: View {
      @State private var reset: Bool = false
      @State private var witnessPresent = false
      @State private var timeAlive: String = "n/a"
      @State private var useShortForm: Bool = true
      @State private var useUppercase: Bool = true
      
    var audioUnitComponents: AudioUnitComponents
    
      var body: some View {
          VStack(spacing: 20) {
              Text("Witness view is \(witnessPresent ? "" : "not") rendered")
              Text("Witness view time alive: \(timeAlive)")
              
              ScrollView {
                  LazyVStack {
                      ForEach(0..<audioUnitComponents.audioUnitComponents.count, id: \.self) { idx in
                              UnitView(timeAlive: $timeAlive, useShortForm: $useShortForm, component: audioUnitComponents.audioUnitComponents[idx], useUppercase: useUppercase)
                                  .onAppear { witnessPresent = true }
                                  .onDisappear { witnessPresent = false }
                      }
                  }
              }
              .frame(width:200, height: 300)
              .font(.title)
              
              Button("Reset") {
                  self.reset.toggle()
                  self.timeAlive = "n/a"
              }
              
          }
          .font(.title2)
          .id(reset)
      }
      
      struct UnitView: View {
          @State private var alive: Int = 0
          @State private var isRed = false
          @Binding var timeAlive: String
          @Binding var useShortForm: Bool
          var component: Component
          let useUppercase: Bool
          
          let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
          
          var body: some View {
              component.componentIcon
                  .foregroundColor(isRed ? Color.red : Color.primary)
                  .onTapGesture { isRed.toggle() }
                  .onReceive(timer) { _ in
                      self.alive += 1
                      self.timeAlive = "\(alive) \(useShortForm ? "s" : "seconds")"
                      
                      if useUppercase {
                          self.timeAlive = self.timeAlive.uppercased()
                      }
                  }
          }
      }
  }
