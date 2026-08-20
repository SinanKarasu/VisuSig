import Foundation
import Observation

public enum PortDirection: String, Codable, Sendable {
    case input
    case output
}

public struct GraphPort: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var direction: PortDirection

    public init(id: UUID = UUID(), name: String, direction: PortDirection) {
        self.id = id
        self.name = name
        self.direction = direction
    }
}

@Observable
public final class GraphNode<Payload>: Identifiable {
    public let id: UUID
    public var title: String
    public var payload: Payload
    public var ports: [GraphPort]

    public init(id: UUID = UUID(), title: String, payload: Payload, ports: [GraphPort] = []) {
        self.id = id
        self.title = title
        self.payload = payload
        self.ports = ports
    }
}

@Observable
public final class GraphEdge<Payload>: Identifiable {
    public let id: UUID
    public let sourceNodeID: UUID
    public let sourcePortID: UUID
    public let targetNodeID: UUID
    public let targetPortID: UUID
    public var payload: Payload

    public init(
        id: UUID = UUID(),
        sourceNodeID: UUID,
        sourcePortID: UUID,
        targetNodeID: UUID,
        targetPortID: UUID,
        payload: Payload
    ) {
        self.id = id
        self.sourceNodeID = sourceNodeID
        self.sourcePortID = sourcePortID
        self.targetNodeID = targetNodeID
        self.targetPortID = targetPortID
        self.payload = payload
    }
}

public enum MeshConnectionError: Error, Equatable {
    case sourceNodeMissing
    case targetNodeMissing
    case sourcePortMissing
    case targetPortMissing
    case incompatiblePortDirections
    case duplicateConnection
}

@Observable
public final class Mesh<NodePayload, EdgePayload> {
    public private(set) var nodes: [GraphNode<NodePayload>] = []
    public private(set) var edges: [GraphEdge<EdgePayload>] = []

    public init() {}

    public func addNode(_ node: GraphNode<NodePayload>) {
        nodes.append(node)
    }

    @discardableResult
    public func connect(
        sourceNodeID: UUID,
        sourcePortID: UUID,
        targetNodeID: UUID,
        targetPortID: UUID,
        payload: EdgePayload
    ) throws -> GraphEdge<EdgePayload> {
        guard let sourceNode = nodes.first(where: { $0.id == sourceNodeID }) else {
            throw MeshConnectionError.sourceNodeMissing
        }
        guard let targetNode = nodes.first(where: { $0.id == targetNodeID }) else {
            throw MeshConnectionError.targetNodeMissing
        }
        guard let sourcePort = sourceNode.ports.first(where: { $0.id == sourcePortID }) else {
            throw MeshConnectionError.sourcePortMissing
        }
        guard let targetPort = targetNode.ports.first(where: { $0.id == targetPortID }) else {
            throw MeshConnectionError.targetPortMissing
        }
        guard sourcePort.direction == .output, targetPort.direction == .input else {
            throw MeshConnectionError.incompatiblePortDirections
        }
        guard !edges.contains(where: {
            $0.sourcePortID == sourcePortID && $0.targetPortID == targetPortID
        }) else {
            throw MeshConnectionError.duplicateConnection
        }

        let edge = GraphEdge(
            sourceNodeID: sourceNodeID,
            sourcePortID: sourcePortID,
            targetNodeID: targetNodeID,
            targetPortID: targetPortID,
            payload: payload
        )
        edges.append(edge)
        return edge
    }

    public func removeEdge(id: UUID) {
        edges.removeAll { $0.id == id }
    }

    public func removeNode(id: UUID) {
        nodes.removeAll { $0.id == id }
        edges.removeAll { $0.sourceNodeID == id || $0.targetNodeID == id }
    }
}
