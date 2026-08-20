import Foundation
import CoreGraphics
import VisualMesh

@Observable
class EdgeBase: Identifiable {
    var id = UUID()
    var startPort: PortBase
    var endPort: PortBase

    var data: CubicBezierData?
    let signalPayload: SignalEdgePayload

    init(
        start: PortBase,
        end: PortBase,
        data: CubicBezierData? = nil,
        signalPayload: SignalEdgePayload = SignalEdgePayload()
    ) {
        self.startPort = start
        self.endPort = end
        self.signalPayload = signalPayload
        self.data = CubicBezierData(edge: self)
    }

    func attach(_ instrument: any SoftwareInstrument) {
        signalPayload.attach(instrument)
    }

    func detachInstrument(id: UUID) {
        signalPayload.detachInstrument(id: id)
    }

    func publishTelemetry(voltage: Double, frequency: Double) {
        signalPayload.publish(voltage: voltage, frequency: frequency)
    }

    enum CodingKeys: CodingKey {
        case id
        case startPort
        case endPort
        case data
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startPort = try container.decode(PortBase.self, forKey: .startPort)
        endPort = try container.decode(PortBase.self, forKey: .endPort)
        signalPayload = SignalEdgePayload()
        data = CubicBezierData(edge: self)
    }
}


extension EdgeBase: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension EdgeBase: Equatable {
    static func == (lhs: EdgeBase, rhs: EdgeBase) -> Bool {
        return lhs.startPort == rhs.startPort && lhs.endPort == rhs.endPort
    }
}

extension EdgeBase: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startPort, forKey: .startPort)
        try container.encode(endPort, forKey: .endPort)
    }
}
