import SwiftUI

struct MapView: View {
    @ObservedObject var selection: SelectionHandler
	var mesh: Mesh

    var body: some View {
        ZStack {
            NodeMapView(selection: selection, nodes: mesh.nodes)
            EdgeMapView(selection: selection, edges: mesh.edges)
        }
    }
}
