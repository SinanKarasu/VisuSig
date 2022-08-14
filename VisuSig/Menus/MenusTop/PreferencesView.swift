//
//  PreferencesView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 4/28/22.
//

import SwiftUI

struct PreferencesView: View {
      
       var body: some View {
           
           TabView {
               AccountSetting()
                   .tabItem({ tab("Account", icon: "person.crop.rectangle") })
               
               EditorSettings()
                   .tabItem({ tab("Editor", icon: "rectangle.and.pencil.and.ellipsis") })
   
               AdvancedSettings()
                   .tabItem({ tab("Advanced", icon: "gearshape.2") })
   
           }.frame(width: 400)
       }
       
       @ViewBuilder func tab(_ name: String, icon: String) -> some View {
           Image(systemName: icon)
           Text(name)
       }
   }
   
   struct AccountSetting: View {
       @State private var username = ""
       @State private var password = ""
       
       var body: some View {
           GroupBox(label: Text("Credentials") ) {
               VStack {
                   Text("Username")
                   TextField("", text: $username)
                   
                   Text("Password")
                   SecureField("", text: $password)
               }
               .padding(20)
           }.padding(20)
       }
   }
   
   struct EditorSettings: View {
       @State private var fontSize: Double = 12
       @State private var family = 1
       @State private var scheme = 1
       @State private var useImages = true
   
       var body: some View {
           VStack {
               GroupBox(label: Text("Font") ) {
                   VStack {
                       Picker("Font Family", selection: $family) {
                           Text("Arial").tag(1)
                           Text("Helvetica").tag(2)
                           Text("Menlo").tag(3)
                       }
                       Slider(value: $fontSize, in: 8...32, step: 1, label: { Text("Font Size (\(Int(fontSize)))")})
                   }
                   .padding(20)
               }
               
               GroupBox(label: Text("Appearance") ) {
                   VStack {
                       Picker("Scheme", selection: $scheme) {
                           Text("Dark").tag(1)
                           Text("Light").tag(2)
                       }
                       
                       Toggle(isOn: $useImages, label: { Text("Use Images")})
                   }
                   .padding(20)
               }
           }.padding(20)
       }
   }
   
   struct AdvancedSettings: View {
       @State private var logConnection = true
       @State private var logfile = ""
   
       var body: some View {
           GroupBox(label: Text("Network Connection") ) {
               VStack {
                   Toggle(isOn: $logConnection, label: { Text("Output log enabled")})
                   
                   Divider()
                   
                   Text("Log filename")
                   TextField("", text: $logfile)
               }
               .padding(20)
           }.padding(20)
       }
   }
   
