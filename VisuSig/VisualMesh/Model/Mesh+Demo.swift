import Foundation
import CoreGraphics

extension Mesh {
    /// Creates the initial AudioGraph with a Source node and an Output node
    /// arranged vertically so the user can immediately wire them up or
    /// drop effects in between.
    static func sampleMesh() -> Mesh {
        let graph = AudioGraph()

        // --- Source node (audio file player) ---
        let source = NodeBase(text: "Audio Source", position: CGPoint(x: 0, y: -220), payload: nil, role: .source)
        source.addPort(port: PortBase(node: source, name: "Out", portType: .output))
        graph.nodes.append(source)   // bypass addNode to avoid auto-port addition

        // --- Output node (hardware output) ---
        let output = NodeBase(text: "Output", position: CGPoint(x: 0, y: 220), payload: nil, role: .output)
        output.addPort(port: PortBase(node: output, name: "In", portType: .input))
        graph.nodes.append(output)

        return graph
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
