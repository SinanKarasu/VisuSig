import SwiftUI

struct EdgeMapView: View {
    @ObservedObject var selection: SelectionHandler
    @Binding var edges: [EdgeBase]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(self.edges, id: \.self) { edge in
                    WireEditView(edgeProxy: EdgeProxy(edge: edge), selection: selection, showPoints: true)
                        .offset(proxy.size / 2.0)
                }
            }
        }
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
