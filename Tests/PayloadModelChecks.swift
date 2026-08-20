import Foundation

@main
struct PayloadModelChecks {
    static func main() throws {
        let row = AtlasStatementRow(statementNumber: 100,
                                    applyStatement: "APPLY, DC SIGNAL, VOLTAGE 5 V",
                                    resource: "DC-SUPPLY-3",
                                    target: "HI R10-HI")

        let statement = try AtlasProgramEmitter.emit(row: row)
        precondition(statement == " 000100 APPLY, DC SIGNAL USING 'DC-SUPPLY-3', VOLTAGE 5 V, CNX HI R10-HI $")

        let program = try AtlasProgramEmitter.emit(rows: [row], programName: "PAYLOAD-CHECK")
        precondition(program.hasPrefix(" 000001 BEGIN, ATLAS PROGRAM 'PAYLOAD-CHECK' $"))
        precondition(program.contains(" 000010 COMMENCE, MAIN PROCEDURE $"))
        precondition(program.hasSuffix(" 999999 TERMINATE, ATLAS PROGRAM 'PAYLOAD-CHECK' $"))

        precondition(row.payload.kind == .atlasStatement)
        precondition(row.payload[field: "resource"] == "DC-SUPPLY-3")

        do {
            _ = try AtlasProgramEmitter.emit(row: AtlasStatementRow(
                statementNumber: 110,
                applyStatement: "APPLY, SHORT",
                resource: "",
                target: "P1 P2"
            ))
            preconditionFailure("Missing resources must be rejected")
        } catch AtlasEmissionError.resourceRequired(110) {
            // Expected.
        }

        print("Payload model checks passed")
    }
}
