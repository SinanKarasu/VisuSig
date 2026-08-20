import SwiftUI

struct MapView: View {
    var selection: SelectionHandler
	var mesh: Mesh

    var body: some View {
        ZStack {
            NodeMapView(selection: selection, mesh: mesh)
            EdgeMapView(selection: selection, edges: mesh.edges)
        }
    }
}
