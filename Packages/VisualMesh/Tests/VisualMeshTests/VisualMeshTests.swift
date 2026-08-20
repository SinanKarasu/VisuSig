import Testing
@testable import VisualMesh

@Suite @MainActor
struct VisualMeshTests {
    @Test func instrumentReceivesOnlyItsEdgesTelemetry() throws {
        let oscilloscope = VirtualOscilloscope(capacity: 2)
        let observedPayload = SignalEdgePayload()
        let otherPayload = SignalEdgePayload()
        observedPayload.attach(oscilloscope)

        observedPayload.publish(voltage: 1, frequency: 440)
        otherPayload.publish(voltage: 99, frequency: 880)
        observedPayload.publish(voltage: 2, frequency: 440)
        observedPayload.publish(voltage: 3, frequency: 440)

        #expect(oscilloscope.voltageHistory.map(\.voltage) == [2, 3])
    }

    @Test func connectionValidatesPortDirection() {
        let mesh = Mesh<String, SignalEdgePayload>()
        let input = GraphPort(name: "In", direction: .input)
        let output = GraphPort(name: "Out", direction: .output)
        let first = GraphNode(title: "First", payload: "", ports: [input])
        let second = GraphNode(title: "Second", payload: "", ports: [output])
        mesh.addNode(first)
        mesh.addNode(second)

        #expect(throws: MeshConnectionError.incompatiblePortDirections) {
            try mesh.connect(
                sourceNodeID: first.id,
                sourcePortID: input.id,
                targetNodeID: second.id,
                targetPortID: output.id,
                payload: SignalEdgePayload()
            )
        }
    }
}
