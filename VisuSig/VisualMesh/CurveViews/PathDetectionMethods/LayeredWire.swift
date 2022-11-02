//
//  File2.swift
//  SiKBezierOffset
//
//  Created by Sinan Karasu on 2/8/22.
//

import SwiftUI


struct LayeredWire: View {
    @ObservedObject var cubicBezierData: CubicBezierData
    @ObservedObject var selection: SelectionHandler
    @State private var pt = CGPoint(x: 50, y: 30)

    let primaryColor = Color.blue


    var body: some View {
        let secondaryColor = primaryColor.opacity(0.7)

        let g = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onEnded {
                self.pt = $0.location// .applying(.init(translationX: -20, y: -20))
                print("Got a Wire gesture:\(self.pt)")
            }

        let offset: CGFloat = 3
        let offsetPath = offSetBezierPathShape2(by: offset, from: cubicBezierData.from.position, to: cubicBezierData.to.position, withControl: cubicBezierData.cp1, and: cubicBezierData.cp2)
        let path = Path { newPath in
            newPath.addPath(offsetPath)
            newPath.addLine(to: cubicBezierData.to.position)
            newPath.addCurve(to: cubicBezierData.from.position, control1: cubicBezierData.cp2, control2: cubicBezierData.cp1)
            newPath.closeSubpath()
        }

//        let c1 = path.contains(pt, eoFill: true) ? "true" : "false"
//        let c2 = path.contains(pt, eoFill: false) ? "true" : "false"
        GeometryReader { _ in
            ZStack {
                // Text(String("\(cubicBezierData.from.position) : \(cubicBezierData.to.position)")).position(cubicBezierData.from.position)
                path
                    .fill(Color.cyan, style: FillStyle(eoFill: false, antialiased: false))
                    .contentShape(path)
                    .gesture(g)
                                        .contextMenu {  // Wire ops
                                            Button("⛑ - Delete Wire", action: {
                                                print("delete")
                                                Mesh.deleteEdge(edge: cubicBezierData.edge)
                                            })
                                            Button("♦️♦️♦️ - Diamonds", action: {
                                            })
                                        }


                Path { p in
                    p.move(to: cubicBezierData.from.position)
                    p.addLine(to: cubicBezierData.cp1)
                }
                .stroke(secondaryColor, lineWidth: 2)

                Path { p in
                    p.move(to: cubicBezierData.to.position)
                    p.addLine(to: cubicBezierData.cp2)
                }.stroke(secondaryColor, lineWidth: 2)

//                let c1 = path.contains(pt, eoFill: true) ? "true" : "false"
//                let c2 = path.contains(pt, eoFill: false) ? "true" : "false"
//                let _ = print("c1:\(c1), c2:\(c2)")
                CurvePointView(point: $cubicBezierData.cp1, color: .red)
                CurvePointView(point: $cubicBezierData.cp2, color: .green)
            }
        }
    }

//    private func theShape() -> some View {
//
//    }

    private func offSetBezierPathShape2(by offset: CGFloat, from point1: CGPoint, to point2: CGPoint, withControl controlPoint1: CGPoint, and controlPoint2: CGPoint) -> Path {
        var lastPoint = cubicBezier(at: 0, point1: point1, point2: point2, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        let path = Path { path in
            let numberOfPoints = 100
            for i in 1 ... numberOfPoints {
                let time = CGFloat(i) / CGFloat(numberOfPoints)
                let point = cubicBezier(at: time, point1: point1, point2: point2, controlPoint1: controlPoint1, controlPoint2: controlPoint2)

                // calculate the angle to the offset point
                // this is the angle between the two points, plus 90 degrees (pi / 2.0)

                let angle = atan2(point.y - lastPoint.y, point.x - lastPoint.x) + .pi / 2

                if i == 1 {
                    path.move(to: calculateOffset(of: lastPoint, by: offset, angle: angle))
                }

                lastPoint = point
                path.addLine(to: calculateOffset(of: lastPoint, by: offset, angle: angle))
            }
        }

        return path
    }

    private func calculateOffset(of point: CGPoint, by offset: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(x: point.x + cos(angle) * offset, y: point.y + sin(angle) * offset)
    }

    private func cubicBezier(at time: CGFloat, point1: CGPoint, point2: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) -> CGPoint {
        let oneMinusT = 1.0 - time
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT

        let tSquared = time * time
        let tCubed = tSquared * time

        var x = point1.x * oneMinusTCubed
        x += 3.0 * oneMinusTSquared * time * controlPoint1.x
        x += 3.0 * oneMinusT * tSquared * controlPoint2.x
        x += tCubed * point2.x

        var y = point1.y * oneMinusTCubed
        y += 3.0 * oneMinusTSquared * time * controlPoint1.y
        y += 3.0 * oneMinusT * tSquared * controlPoint2.y
        y += tCubed * point2.y

        return CGPoint(x: x, y: y)
    }
}
