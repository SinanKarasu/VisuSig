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
            // Add customize toolbar menu items
            ToolbarCommands()

            // Add text editing menu items
            TextEditingCommands()

            // Addition to the built-in help menu
            MyHelpCommands()

            // A custom Find menu
            MyFindCommands()

            // A custom Build menu
            MyBuildCommands()
        }

        Settings {
            PreferencesView()
        }
    }
}
