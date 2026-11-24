//
//  VisuSigApp.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/21/22.
//

import SwiftUI

@main
struct VisuSigApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            MusicProjectCommands()
            #if os(macOS)
            // Add customize toolbar menu items
            ToolbarCommands()
            #endif

            // Add text editing menu items
            TextEditingCommands()

            // Addition to the built-in help menu
            MyHelpCommands()

            // A custom Find menu
            MyFindCommands()

            // A custom Build menu
            MyBuildCommands()
        }

        #if os(macOS)
        Settings {
            PreferencesView()
        }
        #endif
    }
}
