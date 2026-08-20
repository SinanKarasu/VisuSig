import Foundation

/// The first spreadsheet-shaped ATLAS authoring record.
///
/// The four columns preserve intent separately. They are not a replacement for
/// the ATLAS grammar; they are a small authoring form that can be serialized to
/// an ATLAS APPLY statement and later lowered directly to TestIR.
struct AtlasStatementRow: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var statementNumber: Int
    var applyStatement: String
    var resource: String
    var target: String

    init(id: UUID = UUID(),
         statementNumber: Int,
         applyStatement: String,
         resource: String,
         target: String) {
        self.id = id
        self.statementNumber = statementNumber
        self.applyStatement = applyStatement
        self.resource = resource
        self.target = target
    }

    var payload: Payload {
        Payload(
            id: id,
            kind: .atlasStatement,
            title: "\(statementNumber) APPLY",
            fields: [
                PayloadField("statementNumber", label: "Statement", value: String(statementNumber)),
                PayloadField("applyStatement", label: "Apply", value: applyStatement),
                PayloadField("resource", label: "Resource", value: resource),
                PayloadField("target", label: "Target", value: target),
            ]
        )
    }
}

enum AtlasEmissionError: LocalizedError, Equatable {
    case invalidStatementNumber(Int)
    case applyVerbRequired(String)
    case subjectRequired(Int)
    case resourceRequired(Int)
    case targetRequired(Int)
    case apostropheNotSupported(field: String, statementNumber: Int)
    case duplicateStatementNumber(Int)

    var errorDescription: String? {
        switch self {
        case .invalidStatementNumber(let number):
            return "Statement number must be positive (found \(number))."
        case .applyVerbRequired(let text):
            return "Apply statement must begin with APPLY (found “\(text)”)."
        case .subjectRequired(let number):
            return "Statement \(number) needs an APPLY subject, such as DC SIGNAL."
        case .resourceRequired(let number):
            return "Statement \(number) needs a resource."
        case .targetRequired(let number):
            return "Statement \(number) needs a target connection."
        case .apostropheNotSupported(let field, let number):
            return "Statement \(number) contains an apostrophe in \(field); escaping is not defined in this first cut."
        case .duplicateStatementNumber(let number):
            return "Statement number \(number) is duplicated."
        }
    }
}

struct AtlasProgramEmitter {
    static func emit(rows: [AtlasStatementRow],
                     programName: String = "VISUSIG-PAYLOAD") throws -> String {
        let sorted = rows.sorted { $0.statementNumber < $1.statementNumber }
        var seen = Set<Int>()

        let statements = try sorted.map { row -> String in
            guard seen.insert(row.statementNumber).inserted else {
                throw AtlasEmissionError.duplicateStatementNumber(row.statementNumber)
            }
            return try emit(row: row)
        }

        let safeProgramName = programName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !safeProgramName.contains("'") else {
            throw AtlasEmissionError.apostropheNotSupported(field: "program name", statementNumber: 0)
        }

        return ([" 000001 BEGIN, ATLAS PROGRAM '\(safeProgramName)' $",
                 " 000010 COMMENCE, MAIN PROCEDURE $"]
                + statements
                + [" 999999 TERMINATE, ATLAS PROGRAM '\(safeProgramName)' $"])
            .joined(separator: "\n")
    }

    static func emit(row: AtlasStatementRow) throws -> String {
        guard row.statementNumber > 0 else {
            throw AtlasEmissionError.invalidStatementNumber(row.statementNumber)
        }

        let body = row.applyStatement
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "$"))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let clauses = body
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard clauses.first?.uppercased() == "APPLY" else {
            throw AtlasEmissionError.applyVerbRequired(row.applyStatement)
        }
        guard clauses.count >= 2, !clauses[1].isEmpty else {
            throw AtlasEmissionError.subjectRequired(row.statementNumber)
        }

        let resource = row.resource.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resource.isEmpty else {
            throw AtlasEmissionError.resourceRequired(row.statementNumber)
        }
        guard !resource.contains("'") else {
            throw AtlasEmissionError.apostropheNotSupported(field: "resource", statementNumber: row.statementNumber)
        }

        let rawTarget = row.target.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawTarget.isEmpty else {
            throw AtlasEmissionError.targetRequired(row.statementNumber)
        }

        let target = rawTarget.uppercased().hasPrefix("CNX ")
            ? rawTarget
            : "CNX \(rawTarget)"

        var emitted = "APPLY, \(clauses[1]) USING '\(resource)'"
        let characteristics = clauses.dropFirst(2).filter { !$0.isEmpty }
        if !characteristics.isEmpty {
            emitted += ", " + characteristics.joined(separator: ", ")
        }
        emitted += ", \(target) $"

        return String(format: " %06d %@", row.statementNumber, emitted)
    }
}
