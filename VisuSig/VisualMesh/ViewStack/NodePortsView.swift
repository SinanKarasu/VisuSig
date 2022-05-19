
import SwiftUI

struct NodePortsView: View {
    
    //static let width = CGFloat(100)
    @Binding var node: NodeBase
    @ObservedObject var selection: SelectionHandler
    //@GestureState private var gestureState: CGPoint = .zero
    @State var forceUpdate = false
    
    
    var selected: Bool {
        return selection.isNodeSelected(node)
    }
    
    var body: some View {
          ZStack {
                Rectangle()
                    .fill(Color.green)
                    .opacity(0.2)
                    .frame(width: node.size.width, height: node.portAreaHeight)
                
                HStack(spacing: 0) {
                    ForEach(node.ports) { port in
                        PortView(port: port, selection: selection )
                            .id(port)
                    }
                }
            }
    }
    
    func theNodeView(selected: Bool) -> some View {
        let width = node.size.width//CGFloat(100)
        
        return Rectangle()
            .fill(Color.green)
            .overlay(Rectangle()
                .stroke(selected ? Color.red : Color.black, lineWidth: selected ? 5:3))
            .overlay(node.nodeInfo)
        //.multilineTextAlignment(.center)
        //.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)))
            .frame(width: width, height: width, alignment: .center)
        
    }
    
    // Mark: Menus
    func flyoutMenu() -> some View {
        let flyoutMenuOptions = MenuOptions().setupOptions()
        return FlyoutMenuMainView(flyoutMenuOptions: flyoutMenuOptions)
    }
    
    
}

