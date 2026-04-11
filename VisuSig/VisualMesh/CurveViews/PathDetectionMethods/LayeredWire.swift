//
//  File2.swift
//  SiKBezierOffset
//
//  Created by Sinan Karasu on 2/8/22.
//

import SwiftUI

struct LayeredWire: View {
    var cubicBezierData: CubicBezierData
    var selection: SelectionHandler

    let wireColor = Color.cyan

    var body: some View {
        // Snapshot current positions so SwiftUI re-evaluates when ports move
        let fromPos = cubicBezierData.from.position
        let toPos   = cubicBezierData.to.position
        let cp1     = cubicBezierData.cp1
        let cp2     = cubicBezierData.cp2

        let offset: CGFloat = 4
        let offsetPath = offSetBezierPathShape(by: offset, from: fromPos, to: toPos, cp1: cp1, cp2: cp2)

        let wirePath = Path { p in
            p.addPath(offsetPath)
            p.addLine(to: toPos)
            p.addCurve(to: fromPos, control1: cp2, control2: cp1)
            p.closeSubpath()
        }

        GeometryReader { _ in
            ZStack {
                // ── Filled wire ribbon ─────────────────────────────────
                wirePath
                    .fill(
                        LinearGradient(
                            colors: [wireColor.opacity(0.9), wireColor.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: FillStyle(eoFill: false, antialiased: true)
                    )
                    .contentShape(wirePath)
                    .contextMenu {
                        Button("Delete Wire") {
                            Mesh.deleteEdge(edge: cubicBezierData.edge)
                        }
                    }

                // ── Subtle control-handle guide lines ──────────────────
                Path { p in
                    p.move(to: fromPos)
                    p.addLine(to: cp1)
                }
                .stroke(wireColor.opacity(0.25), lineWidth: 1)

                Path { p in
                    p.move(to: toPos)
                    p.addLine(to: cp2)
                }
                .stroke(wireColor.opacity(0.25), lineWidth: 1)
            }
        }
    }

    // MARK: - Offset ribbon path

    private func offSetBezierPathShape(by offset: CGFloat,
                                       from p1: CGPoint, to p2: CGPoint,
                                       cp1: CGPoint, cp2: CGPoint) -> Path {
        var lastPoint = cubicBezierAt(t: 0, p1: p1, p2: p2, cp1: cp1, cp2: cp2)
        return Path { path in
            let steps = 60
            for i in 1...steps {
                let t = CGFloat(i) / CGFloat(steps)
                let point = cubicBezierAt(t: t, p1: p1, p2: p2, cp1: cp1, cp2: cp2)
                let angle = atan2(point.y - lastPoint.y, point.x - lastPoint.x) + .pi / 2
                if i == 1 { path.move(to: sidePoint(lastPoint, offset: offset, angle: angle)) }
                lastPoint = point
                path.addLine(to: sidePoint(lastPoint, offset: offset, angle: angle))
            }
        }
    }

    private func sidePoint(_ p: CGPoint, offset: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: p.x + cos(angle) * offset, y: p.y + sin(angle) * offset)
    }

    private func cubicBezierAt(t: CGFloat, p1: CGPoint, p2: CGPoint,
                                cp1: CGPoint, cp2: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u*u*u*p1.x + 3*u*u*t*cp1.x + 3*u*t*t*cp2.x + t*t*t*p2.x,
            y: u*u*u*p1.y + 3*u*u*t*cp1.y + 3*u*t*t*cp2.y + t*t*t*p2.y
        )
    }
}
