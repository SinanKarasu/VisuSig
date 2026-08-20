import SwiftUI

struct EdgeMapView: View {
    var selection: SelectionHandler
    var edges: [EdgeBase]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(self.edges, id: \.self) { edge in
                    WireEditView(edgeProxy: EdgeProxy(edge: edge), selection: selection)
                        .offset(proxy.size / 2.0)

                    if !edge.signalPayload.instruments.isEmpty {
                        EdgeInstrumentView(edge: edge)
                            .position(instrumentPosition(for: edge, canvasSize: proxy.size))
                    }
                }
            }
        }
    }

    private func instrumentPosition(for edge: EdgeBase, canvasSize: CGSize) -> CGPoint {
        let midpoint = CGPoint(
            x: (edge.startPort.node.position.x + edge.endPort.node.position.x) / 2,
            y: (edge.startPort.node.position.y + edge.endPort.node.position.y) / 2
        )
        return CGPoint(
            x: canvasSize.width / 2 + midpoint.x,
            y: canvasSize.height / 2 + midpoint.y - 72
        )
    }
}

// struct EdgeMapView_Previews: PreviewProvider {
//
//    static let proxy1 = EdgeProxy(id: UUID(),
//                                  start: .zero,
//                                  end: CGPoint(x: -100, y: 30))
//    static let proxy2 = EdgeProxy(id: UUID(),
//                                  start: .zero,
//                                  end: CGPoint(x: 100, y: 30))
//
//    @State static var edges = [proxy1, proxy2]
//
//    static var previews: some View {
//        EdgeMapView(selection: SelectionHandler(), edges: $edges)
//    }
// }
