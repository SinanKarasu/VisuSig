import SwiftUI

struct NodeView: View {
    @ObservedObject var node: NodeBase
    @ObservedObject var selection: SelectionHandler
    
    var selected: Bool {
        return selection.isNodeSelected(node)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.green)
                    .overlay(Rectangle()
                        .stroke(selected ? Color.red : Color.black, lineWidth: selected ? 5 : 3))
                    .overlay(node.nodeInfo)
                    .frame(width: node.size.width, height: node.size.height, alignment: .center)
                    .opacity(0.4)
                    .contextMenu {  // AVAudioNode ops
                        Button("⛑ - Add Port", action: {
                            DispatchQueue.main.async {
                                self.selection.selectNode(node)
                                node.addPort(port: PortBase(node: node, name: "\(node.ports.count)"))
                                // forceUpdate.toggle()
                            }
                        })
                        Button("♠️♠️ - Spades", action: {
                            print("------------------")
                        })
                        Menu("Nested Root") {
                            Button("Nested #1") {}
                            Button("Nested #2") {}
                            Button("Nested #3") {}
                        }
                    }
                    .onTapGesture { // This one causes delay
                        self.selection.selectNode(node)
                    }
                if selected {
                    flyoutMenu()
                        .offset(x: node.size.width / 2, y: -node.size.height / 2)
                }
                NodePortsView(node: node, selection: self.selection)
                    .offset(x: 0, y: node.size.height / 2 + node.portAreaHeight / 2)
                
            }
            .offset(x: node.position.x, y: node.position.y)

            .frame(width: node.size.width, height: node.size.height, alignment: .center)
            .coordinateSpace(name: node.id.uuidString)
        }
    }
    
    
    // MARK: Menus
    func flyoutMenu() -> some View {
        let flyoutMenuOptions = MenuOptions().setupOptions()
        return FlyoutMenuMainView(flyoutMenuOptions: flyoutMenuOptions)
    }
}

