import SwiftUI
import VisualMesh
import VisualMeshUI

/// Edge payload for the read-only execution-order projection.
struct ExecutionOrder: Hashable, Sendable {}

@Observable
final class AtlasPayloadWorkbenchModel {
    var programName = "VISUSIG-PAYLOAD"
    var rows: [AtlasStatementRow] {
        didSet { rebuildGraph() }
    }

    /// Rebuilt from `rows` on every edit; the table is the authoring form.
    private(set) var mesh = Mesh<Payload, ExecutionOrder>()
    private(set) var layout = MeshLayout2D()

    init(rows: [AtlasStatementRow] = AtlasPayloadWorkbenchModel.exampleRows) {
        self.rows = rows
        rebuildGraph()
    }

    var generatedProgram: String {
        do {
            return try AtlasProgramEmitter.emit(rows: rows, programName: programName)
        } catch {
            return "-- \(error.localizedDescription)"
        }
    }

    var generationError: String? {
        do {
            _ = try AtlasProgramEmitter.emit(rows: rows, programName: programName)
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func addRow() {
        let nextNumber = (rows.map(\.statementNumber).max() ?? 90) + 10
        rows.append(AtlasStatementRow(statementNumber: nextNumber,
                                      applyStatement: "APPLY, DC SIGNAL, VOLTAGE 5 V",
                                      resource: "DC-SUPPLY",
                                      target: "HI UUT-PIN"))
    }

    func removeRow(id: UUID) {
        rows.removeAll { $0.id == id }
    }

    func resetExample() {
        rows = Self.exampleRows
    }

    func binding<Value>(for id: UUID,
                        _ keyPath: WritableKeyPath<AtlasStatementRow, Value>) -> Binding<Value> {
        Binding(
            get: {
                guard let row = self.rows.first(where: { $0.id == id }) else {
                    preconditionFailure("Binding requested for missing ATLAS row \(id)")
                }
                return row[keyPath: keyPath]
            },
            set: { newValue in
                guard let index = self.rows.firstIndex(where: { $0.id == id }) else { return }
                self.rows[index][keyPath: keyPath] = newValue
            }
        )
    }

    private func rebuildGraph() {
        let mesh = Mesh<Payload, ExecutionOrder>()
        let layout = MeshLayout2D()

        let sorted = rows.sorted { $0.statementNumber < $1.statementNumber }
        var previous: GraphNode<Payload>?

        for (index, row) in sorted.enumerated() {
            let input = GraphPort(name: "In", direction: .input)
            let next = GraphPort(name: "Next", direction: .output)
            let node = GraphNode(title: row.payload.title, payload: row.payload, ports: [input, next])
            mesh.addNode(node)
            layout.setPosition(
                CGPoint(x: 0, y: CGFloat(index) * 150 - CGFloat(max(sorted.count - 1, 0)) * 75),
                for: node.id
            )

            if let previous {
                _ = try? mesh.connect(sourceNodeID: previous.id, sourcePortID: previous.ports[1].id,
                                      targetNodeID: node.id, targetPortID: input.id,
                                      payload: ExecutionOrder())
            }
            previous = node
        }

        self.mesh = mesh
        self.layout = layout
    }

    static let exampleRows = [
        AtlasStatementRow(statementNumber: 100,
                          applyStatement: "APPLY, DC SIGNAL, VOLTAGE 5 V",
                          resource: "DC-SUPPLY-3",
                          target: "HI R10-HI"),
        AtlasStatementRow(statementNumber: 110,
                          applyStatement: "APPLY, SHORT",
                          resource: "CONN-0",
                          target: "RES-LO UUT-PIN"),
    ]
}

struct PayloadWorkbenchView: View {
    @State private var model = AtlasPayloadWorkbenchModel()
    @State private var canvasState = MeshCanvasState()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            WorkspaceSplitView {
                VStack(spacing: 0) {
                    spreadsheet
                        .frame(minHeight: 210)

                    Divider()

                    programPreview
                        .frame(minHeight: 180)
                }
                .frame(minWidth: PlatformUI.desktopMinimum(650), idealWidth: 760)

                VStack(alignment: .leading, spacing: 0) {
                    Label("Execution order as payload graph", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    Divider()
                    MeshCanvas(mesh: model.mesh, layout: model.layout, state: canvasState) { node in
                        VStack(spacing: 2) {
                            Text(node.payload.title)
                            Text("\(node.payload[field: "resource"] ?? "?") → \(node.payload[field: "target"] ?? "?")")
                                .font(.system(size: 9))
                                .opacity(0.75)
                        }
                    }
                    .nodeTint { _ in Color(red: 0.08, green: 0.55, blue: 0.62) }
                    .readOnly()
                }
                .frame(minWidth: PlatformUI.desktopMinimum(420))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ATLAS Statement Payload")
                    .font(.title2.weight(.semibold))
                Text("The table is the authoring form; ATLAS text and the visual graph are projections.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            TextField("Program", text: $model.programName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 190)

            Button("Reset Example", systemImage: "arrow.counterclockwise") {
                model.resetExample()
            }
            Button("Add Statement", systemImage: "plus") {
                model.addRow()
            }
            .keyboardShortcut("+", modifiers: .command)
        }
        .padding(12)
    }

    private var spreadsheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView([.horizontal, .vertical]) {
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                    GridRow {
                        columnHeader("Statement #", width: 100)
                        columnHeader("Apply statement", width: 330)
                        columnHeader("Resource", width: 150)
                        columnHeader("Target", width: 190)
                        Color.clear.frame(width: 24, height: 1)
                    }

                    Divider().gridCellColumns(5)

                    ForEach(model.rows) { row in
                        GridRow {
                            TextField("100",
                                      value: model.binding(for: row.id, \.statementNumber),
                                      format: .number)
                                .frame(width: 100)
                            TextField("APPLY, DC SIGNAL, VOLTAGE 5 V",
                                      text: model.binding(for: row.id, \.applyStatement))
                                .frame(width: 330)
                            TextField("DC-SUPPLY-3",
                                      text: model.binding(for: row.id, \.resource))
                                .frame(width: 150)
                            TextField("HI R10-HI",
                                      text: model.binding(for: row.id, \.target))
                                .frame(width: 190)
                            Button {
                                model.removeRow(id: row.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Remove statement")
                        }
                    }
                }
                .textFieldStyle(.roundedBorder)
                .padding(12)
            }

            Spacer(minLength: 0)
        }
        .background(PlatformUI.controlBackground)
    }

    private var programPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Generated ATLAS", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.headline)
                Spacer()
                if let error = model.generationError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(2)
                } else {
                    Label("Ready", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            ScrollView([.horizontal, .vertical]) {
                Text(model.generatedProgram)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(PlatformUI.textBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(PlatformUI.separator))
        }
        .padding(12)
    }

    private func columnHeader(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
    }
}
