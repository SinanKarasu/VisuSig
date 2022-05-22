
import Foundation
import CoreGraphics

class Mesh: ObservableObject {

    let snapToGrid = false
    static var meshes = [Mesh]()
    static func deleteEdge(edge: EdgeBase) {
        for mesh in meshes {
            mesh.removeEdge(edge: edge)
        }
        print("deleting edge")
    }
    let meshGranularity: CGFloat = 30.0

    @Published var nodes = [NodeBase]()
    @Published var editingText: String


    init() {
        editingText = ""
        Mesh.meshes.append(self)
    }

    init(storage: MeshStorageProxy) {
        editingText = ""
        nodes = storage.nodes
        edges = storage.edges
        Mesh.meshes.append(self)
        //rebuildLinks()
    }

    func removeEdge(edge: EdgeBase) {
        edges.removeAll{$0.id == edge.id}
    }
    var edges = [EdgeBase]()
    {
        didSet {
            //rebuildLinks()
            objectWillChange.send()
        }
    }



    func nodeWithID(_ nodeID: UUID) -> NodeBase? {
        return nodes.filter({ $0.id == nodeID }).first
    }

    func edgeWithID(_ edgeID: UUID) -> EdgeBase? {
        return edges.filter({ $0.id == edgeID }).first
    }


    func portWithID(_ portID: UUID) -> PortBase? {
        var retVal: PortBase? = nil
        nodes.forEach { node in
            let aPort = node.ports.filter({ $0.id == portID }).first
            if  aPort != nil {
                retVal = aPort
                return
            }
        }
        return retVal
    }

}



extension Mesh {

    func updateNodeText(_ srcNode: NodeBase, string: String) {
        srcNode.text = string
    }

    func positionNode(_ node: NodeBase, position: CGPoint) {
        node.position = position
        //rebuildLinks()
    }

    func processNodeTranslation(_ translation: CGSize, nodes: [DragInfo], snapToGrid: Bool = false) {
        nodes.forEach({ draginfo in
            if let node = nodeWithID(draginfo.id) {
                var nextPosition = draginfo.originalPosition.translatedBy(x: translation.width, y: translation.height)
                if snapToGrid {
                    //let granularity: CGFloat = 10.0
                    nextPosition.x = (nextPosition.x/meshGranularity).rounded(.toNearestOrEven) * meshGranularity
                    nextPosition.y = (nextPosition.y/meshGranularity).rounded(.toNearestOrEven) * meshGranularity
                }
                positionNode(node, position: nextPosition)
            }
        })
    }

    func roundToTens(x : Double) -> Int {
        return 10 * Int(round(x / 10.0))
    }

}

extension Mesh {

    func addNode(_ node: NodeBase) {
        nodes.append(node)
        node.addPort(port: PortBase(node: node, name: "DefaultPort"))
    }

    func connect(_ parent: PortBase, to child: PortBase) {

        let newedge = EdgeBase(start: parent, end: child)
        let exists = edges.contains(where: { edge in
            return newedge == edge
        })

        guard exists == false else {
            return
        }

        edges.append(newedge)
    }
}

extension Mesh {

    @discardableResult func addDemoChild(_ parent: NodeBase, at point: CGPoint? = nil, defaultPort: Bool = true) -> NodeBase {
        let target = point ?? parent.position
        let child = NodeBase(position: target, text: "child")
        addNode(child)
        connect(parent.ports[0], to: child.ports[0])
        //rebuildLinks()
        return child
    }


    func deleteNodes(_ nodesToDelete: [NodeBase]) {
        for node in nodesToDelete {
            if let delete = nodes.firstIndex(where: { $0 == node }) {
                nodes.remove(at: delete)
                let remainingEdges = edges.filter({ $0.endPort.node != node && $0.startPort.node != node })
                edges = remainingEdges
            }
        }
    }

//    func deleteNodes(_ nodesToDelete: [AVAudioNode]) {
//        deleteNodes(nodesToDelete.map({ $0.id }))
//    }

}

extension Mesh {
    func locateParent(_ node: NodeBase) -> PortBase? {
        let parentedges = edges.filter({ $0.endPort.node.id == node.id })
        if let parentedge = parentedges.first,
           let parentnode = portWithID(parentedge.startPort.node.id) {
            return parentnode
        }
        return nil
    }
}


extension Mesh {
    func meshCoordinates(whereAt: CGPoint, containerSize: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
        return (whereAt - containerSize/2.0 - portalPosition) / zoomScale
    }

}
