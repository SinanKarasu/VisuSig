//
//  ContentView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/21/22.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack {
            //TopCompMenuView(audioUnitComponents: audioUnitComponents)
            //ToolMenu2View()
            //ExampleView()
            MasterMenuView()
            //MasterContentView()
            //DropDownMenu()
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
