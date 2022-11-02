import Foundation
import CoreGraphics

extension Mesh {
    static func sampleMesh() -> Mesh {
        let mesh = AudioGraph()
        let kök = NodeBase(text: "kök", payload: nil)
        mesh.addNode(kök)
        mesh.updateNodeText(kök, string: "Root AVAudioNode")
        [
//            (0, 200,  "shelter"),
            (240, 400,   "food")
//            (240,200,  "education")
        ].forEach({ angle, radius, name in
            let center: CGPoint = .zero
            let point = CGPoint(x: center.x + CGFloat(radius) * cos(angle.radians),
                                y: center.y + CGFloat(radius) * sin(angle.radians))
            let node = mesh.addDemoChild(kök, at: point)
            mesh.updateNodeText(node, string: name)
        })
        return mesh
    }
}

extension Mesh {
    /// angle in radians
    func pointWithCenter(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let deltax = radius * cos(angle)
        let deltay = radius * sin(angle)
        let newpoint = CGPoint(x: center.x + deltax, y: center.y + deltay)
        return newpoint
    }
}

extension Int {
    var radians: CGFloat {
        CGFloat(self) * CGFloat.pi / 180.0
    }
}
