import SwiftUI

struct NodeMapView: View {
    var selection: SelectionHandler
    var nodes: [NodeBase]
    
    var body: some View {
        ZStack {
            ForEach(self.nodes, id: \.visualID) { node in
                //let index = nodes.firstIndex(of: node)
                // let _ = print("nodeMapView\(selection.whereAt)")
                // VStack(spacing: 0) {
                ZStack {
                    NodeView(node: node, selection: self.selection)
                        .onTapGesture {
                            // TODO: sik add the options to TapGesture
                            var add = false
                            if NSEvent.modifierFlags.contains(.option) {
                            } else if NSEvent.modifierFlags.contains(.command) {
                                add = true
                            } else if NSEvent.modifierFlags.contains(.control) {
                            } else if NSEvent.modifierFlags.contains(.shift) {
                            }
                            print("nodeMapView\(selection.whereAt)")
                            self.selection.selectNode(node, add: add)
                        }
                }
            }
        }
    }
}
