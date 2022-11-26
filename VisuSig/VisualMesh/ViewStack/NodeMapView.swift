import SwiftUI

struct NodeMapView: View {
    @ObservedObject var selection: SelectionHandler
    @Binding var nodes: [NodeBase]

    var body: some View {
        ZStack {
            ForEach(self.nodes, id: \.visualID) { node in
                let index = nodes.firstIndex(of: node)
                // let _ = print("nodeMapView\(selection.whereAt)")
                // VStack(spacing: 0) {
                    ZStack {
                    NodeView(node: nodes[index!], selection: self.selection)
                        .offset(x: node.position.x, y: node.position.y)
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
                    NodePortsView(node: nodes[index!], selection: self.selection)
                            .offset(x: node.position.x, y: node.position.y + node.size.height / 2 + node.portAreaHeight / 2)

                    // .id(node)
                    }
            }
        }
    }
}
