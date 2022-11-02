import SwiftUI

struct NodePortsView: View {
    @Binding var node: NodeBase
    @ObservedObject var selection: SelectionHandler


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
}
