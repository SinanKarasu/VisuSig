import Foundation
import CoreGraphics

@Observable
class Mesh {
    let snapToGrid = false
    static var meshes = [Mesh]()
    static func deleteEdge(edge: EdgeBase) {
        for mesh in meshes {
            mesh.removeEdge(edge: edge)
        }
        print("deleting edge")
    }
    let meshGranularity: CGFloat = 30.0

    var nodes = [NodeBase]()
    var editingText: String
    var edges = [EdgeBase]()

    init() {
        editingText = ""
        Mesh.meshes.append(self)
    }

    init(storage: MeshStorageProxy) {
        editingText = ""
        nodes = storage.nodes
        edges = storage.edges
        Mesh.meshes.append(self)
    }

    // MARK: - Overrideable graph-mutation methods
    // These must be in the class body (not extensions) so subclasses can override them.

    func removeEdge(edge: EdgeBase) {
        edges.removeAll { $0.id == edge.id }
    }

    func addNode(_ node: NodeBase) {
        nodes.append(node)
        // Only add a generic port when the node has no ports pre-configured.
        // Typed nodes (source, effect, output) set their ports before calling addNode.
        if node.ports.isEmpty {
            node.addPort(port: PortBase(node: node, name: "Port", portType: .output))
        }
    }

    func connect(_ parent: PortBase, to child: PortBase) {
        let newedge = EdgeBase(start: parent, end: child)
        let exists = edges.contains(where: { newedge == $0 })
        guard !exists else { return }
        edges.append(newedge)
    }

    func deleteNodes(_ nodesToDelete: [NodeBase]) {
        for node in nodesToDelete {
            if let idx = nodes.firstIndex(where: { $0 == node }) {
                nodes.remove(at: idx)
                edges = edges.filter { $0.endPort.node != node && $0.startPort.node != node }
            }
        }
    }

    // MARK: - Lookups

    func nodeWithID(_ nodeID: UUID) -> NodeBase? {
        nodes.first { $0.id == nodeID }
    }

    func edgeWithID(_ edgeID: UUID) -> EdgeBase? {
        edges.first { $0.id == edgeID }
    }

    func portWithID(_ portID: UUID) -> PortBase? {
        for node in nodes {
            if let port = node.ports.first(where: { $0.id == portID }) { return port }
        }
        return nil
    }
}

// MARK: - Non-overrideable helpers (extensions are fine here)

extension Mesh {
    func updateNodeText(_ srcNode: NodeBase, string: String) {
        srcNode.text = string
    }

    func positionNode(_ node: NodeBase, position: CGPoint) {
        node.position = position
    }

    func processNodeTranslation(_ translation: CGSize, nodes: [DragInfo], snapToGrid: Bool = false) {
        nodes.forEach { draginfo in
            if let node = nodeWithID(draginfo.id) {
                var next = draginfo.originalPosition.translatedBy(x: translation.width, y: translation.height)
                if snapToGrid {
                    next.x = (next.x / meshGranularity).rounded(.toNearestOrEven) * meshGranularity
                    next.y = (next.y / meshGranularity).rounded(.toNearestOrEven) * meshGranularity
                }
                positionNode(node, position: next)
            }
        }
    }

}

extension Mesh {
    func meshCoordinates(whereAt: CGPoint, containerSize: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
        return (whereAt - containerSize / 2.0 - portalPosition) / zoomScale
    }
}
