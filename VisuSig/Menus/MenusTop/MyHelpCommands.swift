//
//  MyHelpCommands.swift
//  VisuSig
//
//  Created by Sinan Karasu on 4/28/22.
//

import SwiftUI


struct MyHelpCommands: Commands {
       var body: some Commands {
           CommandGroup(after: .help) {
               Button("Visit Website", action: contactSupport)

               Button("Contact support", action: contactSupport)
           }
       }

       func contactSupport() { }
   }

   struct MyFindCommands: Commands {
       var body: some Commands {
           CommandMenu("Find") {
               Button("Find text", action: findText)

               Button("Find Regular Expression", action: findRegEx)
           }
       }

       func findText() { }
       func findRegEx() { }
   }

   struct MyBuildCommands: Commands {
       var body: some Commands {
           CommandMenu("Program") {
               Section {
                   Button("Build", action: compile)
                       .keyboardShortcut(KeyboardShortcut(KeyEquivalent("b"), modifiers: [.command]))

                   Menu("Run") {
                       Button("Run", action: runReplace)
                           .keyboardShortcut(KeyboardShortcut(KeyEquivalent("r"), modifiers: [.command]))

                       Button("Run as new instance", action: runNewInstance)
                           .keyboardShortcut(KeyboardShortcut(KeyEquivalent("R"), modifiers: [.command]))
                   }
               }

               Section {
                   Button("Show log", action: showLogs)
                       .keyboardShortcut(KeyboardShortcut(KeyEquivalent("L"), modifiers: [.command, .control]))

                   Button("Disable", action: disableLogs)
               }
           }
       }

       func compile() { }
       func runNewInstance() { }
       func runReplace() { }

       func showLogs() { }
       func disableLogs() { }
   }
