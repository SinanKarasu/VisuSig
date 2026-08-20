import Foundation
import Observation

public struct SignalTelemetry: Sendable, Equatable {
    public let timestamp: ContinuousClock.Instant
    public let voltage: Double
    public let frequency: Double

    public init(
        timestamp: ContinuousClock.Instant = .now,
        voltage: Double,
        frequency: Double
    ) {
        self.timestamp = timestamp
        self.voltage = voltage
        self.frequency = frequency
    }
}

/// A type-erased sink so different instruments can observe one edge.
public protocol SoftwareInstrument: AnyObject, Identifiable where ID == UUID {
    var id: UUID { get }
    var instrumentName: String { get }
    func receive(_ telemetry: SignalTelemetry)
}

/// Live, non-persistent state carried by a signal edge.
@Observable
public final class SignalEdgePayload {
    public private(set) var latestTelemetry: SignalTelemetry?
    public private(set) var instruments: [any SoftwareInstrument] = []

    public init() {}

    public func attach(_ instrument: any SoftwareInstrument) {
        guard !instruments.contains(where: { $0.id == instrument.id }) else { return }
        instruments.append(instrument)
    }

    public func detachInstrument(id: UUID) {
        instruments.removeAll { $0.id == id }
    }

    public func publish(_ telemetry: SignalTelemetry) {
        latestTelemetry = telemetry
        for instrument in instruments {
            instrument.receive(telemetry)
        }
    }

    public func publish(voltage: Double, frequency: Double) {
        publish(SignalTelemetry(voltage: voltage, frequency: frequency))
    }
}

@Observable
public final class VirtualOscilloscope: SoftwareInstrument {
    public let id: UUID
    public let instrumentName: String
    public private(set) var voltageHistory: [SignalTelemetry] = []
    public let samples: AsyncStream<SignalTelemetry>

    private let capacity: Int
    private let continuation: AsyncStream<SignalTelemetry>.Continuation

    public init(
        id: UUID = UUID(),
        instrumentName: String = "Oscilloscope",
        capacity: Int = 500
    ) {
        precondition(capacity > 0)
        self.id = id
        self.instrumentName = instrumentName
        self.capacity = capacity

        let pair = AsyncStream<SignalTelemetry>.makeStream(
            bufferingPolicy: .bufferingNewest(capacity)
        )
        samples = pair.stream
        continuation = pair.continuation
    }

    public func receive(_ telemetry: SignalTelemetry) {
        voltageHistory.append(telemetry)
        if voltageHistory.count > capacity {
            voltageHistory.removeFirst(voltageHistory.count - capacity)
        }
        continuation.yield(telemetry)
    }
}

@Observable
public final class VirtualSpectrumAnalyzer: SoftwareInstrument {
    public let id: UUID
    public let instrumentName: String
    public private(set) var latestAmplitudeByFrequency: [Double: Double] = [:]
    public let samples: AsyncStream<SignalTelemetry>

    private let continuation: AsyncStream<SignalTelemetry>.Continuation

    public init(id: UUID = UUID(), instrumentName: String = "Spectrum Analyzer") {
        self.id = id
        self.instrumentName = instrumentName
        let pair = AsyncStream<SignalTelemetry>.makeStream(bufferingPolicy: .bufferingNewest(256))
        samples = pair.stream
        continuation = pair.continuation
    }

    public func receive(_ telemetry: SignalTelemetry) {
        latestAmplitudeByFrequency[telemetry.frequency] = abs(telemetry.voltage)
        continuation.yield(telemetry)
    }
}
