//
//  EditorControllerView.swift
//  ViewControllerStuff2
//
//  Created by Sinan Karasu on 3/14/21.
//

import SwiftUI


//protocol ViewControllerDelegate: AnyObject {
//    func clasificationOccured(_ viewController: ComponentViewController, identifier: String)
//}


struct AUComponentControllerView: NSViewControllerRepresentable {
    //var selectedIndex: Int
    //var audioUnitManager: AudioUnitManager
    var audioUnitType: AudioUnitType
    var componentViewController: ComponentViewController
    var size: CGSize

    func makeCoordinator() -> Coordinator {
        return Coordinator(self /*, identifierBinding: identifier*/)
    }
    
    class Coordinator /*: ViewControllerDelegate*/ {
        //let identifierBinding: Binding<String>
        //private var parent: ComponentControllerSiKView
//        var shouldUpdateText = true

        func clasificationOccured(_ viewController: ComponentViewController, identifier: String) {
            // whenever the view controller notifies it's delegate about receiving a new idenfifier
            // the line below will propagate the change up to SwiftUI
            //identifierBinding.wrappedValue = identifier
        }

        init(_ parent: AUComponentControllerView/*, identifierBinding: Binding<String>*/) {
            //self.parent = parent

            //self.identifierBinding = identifierBinding
        }

//        init(_ parent: ComponentControllerView) {
//            self.parent = parent
//        }
        

    }
    

    
    func makeNSViewController(context: Context) -> NSViewController {
        logger.info("Making controller")
        return componentViewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        //        if text != nsViewController.textView.string {
        //            context.coordinator.shouldUpdateText = false
        //            nsViewController.textView.string = text
        //            context.coordinator.shouldUpdateText = true
        //        }
    }
}
