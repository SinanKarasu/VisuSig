import Foundation
import CoreGraphics

struct DragInfo {
    var id: UUID
    var originalPosition: CGPoint
}

class SelectionHandler: ObservableObject {
    @Published var draggingNodes = [DragInfo]()
    @Published private(set) var selectedNodeIDs = [UUID]()
    @Published private(set) var selectedPortIDs = [UUID]()
    @Published var whereAt: CGPoint = .zero
    @Published var draggingLocation = CGPoint.zero
    @Published var startLocation = CGPoint.zero
    var firstWirePort: PortBase?
    var secondWirePort: PortBase?
    @Published var editingText: String = ""


    // Modal Views
    @Published var showShapes = false


    func unSelectNodes() {
        selectedNodeIDs = []
    }

    func selectNode(_ node: NodeBase, add: Bool = false) {
        if add {
            selectedNodeIDs.append(node.id) // fix for multiple selection.
            editingText = ""
        } else if !isNodeSelected(node) {
            selectedNodeIDs = [node.id]
            editingText = node.text
        }
    }

    func isNodeSelected(_ node: NodeBase) -> Bool {
        return selectedNodeIDs.contains(node.id)
    }

    func selectedNodes(in mesh: Mesh) -> [NodeBase] {
        return selectedNodeIDs.compactMap({ mesh.nodeWithID($0) })
    }

    func onlySelectedNode(in mesh: Mesh) -> NodeBase? {
        let selectedNodes = self.selectedNodes(in: mesh)
        if selectedNodes.count == 1 {
            return selectedNodes.first
        }
        return nil
    }

    func selectPort(_ port: PortBase, add: Bool = false) {
        if add {
            selectedPortIDs.append(port.id) // fix for multiple selection.
            editingText = ""
        } else if !isPortSelected(port) {
            selectedPortIDs = [port.id]
            editingText = port.name
        }
    }

    func unSelectPort(_ port: PortBase, all: Bool = false) {
        if all {
            selectedPortIDs = []
        } else if !isPortSelected(port) {
            selectedPortIDs = selectedPortIDs.filter {
                $0 != port.id
            }
        }
    }

    func isPortSelected(_ port: PortBase) -> Bool {
        return selectedPortIDs.contains(port.id)
    }

    func startDragging(_ mesh: Mesh) {
        draggingNodes = selectedNodes(in: mesh)
            .map({ DragInfo(id: $0.id, originalPosition: $0.position) })
    }

    func stopDragging(_ mesh: Mesh) {
        draggingNodes = []
    }
}
