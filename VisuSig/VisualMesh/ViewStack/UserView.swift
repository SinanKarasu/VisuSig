
import SwiftUI

//let meshCS = "meshCS"

struct UserView: View {

    @StateObject var mesh: Mesh = Mesh.sampleMesh()


    var body: some View {
        VStack {
            SurfaceView(mesh: mesh)
        }
    }
}

