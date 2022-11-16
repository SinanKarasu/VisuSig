import SwiftUI

struct NodeView: View {
    @Binding var node: NodeBase
    @ObservedObject var selection: SelectionHandler
    
    var selected: Bool {
        return selection.isNodeSelected(node)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                theNodeView(selected: selected)
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
            }
            .frame(width: node.size.width, height: node.size.height, alignment: .center)
            .coordinateSpace(name: node.id.uuidString)
        }
    }
    
    func theNodeView(selected: Bool) -> some View {
        let width = node.size.width// CGFloat(100)
        
        return Rectangle()
            .fill(Color.green)
            .overlay(Rectangle()
                .stroke(selected ? Color.red : Color.black, lineWidth: selected ? 5 : 3))
            .overlay(node.nodeInfo)
        // .multilineTextAlignment(.center)
        // .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)))
            .frame(width: width, height: width, alignment: .center)
    }
    
    
    // MARK: Menus
    func flyoutMenu() -> some View {
        let flyoutMenuOptions = MenuOptions().setupOptions()
        return FlyoutMenuMainView(flyoutMenuOptions: flyoutMenuOptions)
    }
}

