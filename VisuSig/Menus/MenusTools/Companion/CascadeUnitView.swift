//
//  ExampleView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/24/22.
//

import SwiftUI


struct CascadeUnitView: View {
      var body: some View {
          Menu("My Menu") {
              Button("Option A") { }
              Button("Option B") { }
              Menu("Submenu") {
                  Button("Sub option A") { }
                  Button("Sub option B") { }
                  Button("Sub option C") { }
              }
          }
          .frame(width: 150)
          .menuStyle(DefaultMenuStyle())
      }
  }
