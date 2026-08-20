import Foundation
import VisualMesh

/// Example-only ATLAS content. This deliberately does not leak into VisualMesh.
public struct AtlasStatement: Sendable, Equatable {
    public var statementNumber: Int
    public var apply: String
    public var resource: String
    public var target: String

    public init(statementNumber: Int, apply: String, resource: String, target: String) {
        self.statementNumber = statementNumber
        self.apply = apply
        self.resource = resource
        self.target = target
    }
}

public enum AtlasExamples {
    @MainActor
    public static func makeMesh() throws -> Mesh<AtlasStatement, SignalEdgePayload> {
        let mesh = Mesh<AtlasStatement, SignalEdgePayload>()
        let output = GraphPort(name: "Out", direction: .output)
        let input = GraphPort(name: "In", direction: .input)
        let source = GraphNode(
            title: "Apply signal",
            payload: AtlasStatement(
                statementNumber: 100,
                apply: "APPLY, AC SIGNAL",
                resource: "SYNTHESIZER-1",
                target: "J1-1"
            ),
            ports: [output]
        )
        let target = GraphNode(
            title: "Measure signal",
            payload: AtlasStatement(
                statementNumber: 110,
                apply: "MEASURE, AC SIGNAL",
                resource: "DIGITIZER-1",
                target: "J1-1"
            ),
            ports: [input]
        )
        mesh.addNode(source)
        mesh.addNode(target)
        try mesh.connect(
            sourceNodeID: source.id,
            sourcePortID: output.id,
            targetNodeID: target.id,
            targetPortID: input.id,
            payload: SignalEdgePayload()
        )
        return mesh
    }
}
