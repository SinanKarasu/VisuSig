//
//  ContentView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/21/22.
//

import SwiftUI

struct ContentView: View {
    
    private struct DummyOutput : KeyboardOutput {
        func append(_ string: String) {
            
        }
        

        func append(_ character: Character) { }
        func delete() {
            print("delete")
        }
        func clear() {
            print("clear")
        }
    }

    var body: some View {
        VStack {
            //TopCompMenuView(audioUnitComponents: audioUnitComponents)
            //ToolMenu2View()
            //ExampleView()
            MasterMenuView()
            //MasterContentView()
            //DropDownMenu()
            //KeyboardView(output: DummyOutput())
        //}
        
        //        HStack {
        //            HoverAwareDemo1View()
        //            HoverAwareDemo2View()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
