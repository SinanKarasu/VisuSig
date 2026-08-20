import SwiftUI
import VisualMesh

struct EdgeInstrumentView: View {
    let edge: EdgeBase

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(edge.signalPayload.instruments, id: \.id) { instrument in
                if let oscilloscope = instrument as? VirtualOscilloscope {
                    OscilloscopePlot(instrument: oscilloscope)
                } else if let analyzer = instrument as? VirtualSpectrumAnalyzer {
                    SpectrumAnalyzerPlot(instrument: analyzer)
                }
            }
        }
        .padding(8)
        .frame(width: 190)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4, y: 2)
    }
}

private struct OscilloscopePlot: View {
    let instrument: VirtualOscilloscope

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            instrumentHeader(instrument.instrumentName, systemImage: "waveform.path.ecg")
            Canvas { context, size in
                let values = instrument.voltageHistory.suffix(128).map(\.voltage)
                guard values.count > 1 else { return }
                let peak = max(values.map { abs($0) }.max() ?? 1, 0.000_001)
                let step = size.width / CGFloat(values.count - 1)
                var path = Path()
                for (index, value) in values.enumerated() {
                    let point = CGPoint(
                        x: CGFloat(index) * step,
                        y: size.height * (0.5 - CGFloat(value / peak) * 0.45)
                    )
                    index == 0 ? path.move(to: point) : path.addLine(to: point)
                }
                context.stroke(path, with: .color(.green), lineWidth: 1.5)
            }
            .frame(height: 52)
        }
    }
}

private struct SpectrumAnalyzerPlot: View {
    let instrument: VirtualSpectrumAnalyzer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            instrumentHeader(instrument.instrumentName, systemImage: "chart.bar.xaxis")
            GeometryReader { proxy in
                let bins = instrument.latestAmplitudeByFrequency.sorted { $0.key < $1.key }.suffix(24)
                let peak = max(bins.map(\.value).max() ?? 1, 0.000_001)
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(Array(bins), id: \.key) { bin in
                        Rectangle()
                            .fill(.cyan)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: proxy.size.height * CGFloat(bin.value / peak)
                            )
                    }
                }
            }
            .frame(height: 52)
        }
    }
}

private func instrumentHeader(_ title: String, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
        .font(.caption2.weight(.semibold))
        .lineLimit(1)
}
