
import SwiftUI

let meshCoordinateSpace = "meshCoordinateSpace"

struct SurfaceView: View, ContextMenuProtocol  {
    
    @StateObject var mesh: Mesh
    @StateObject var selection = SelectionHandler()
    
    //dragging
    @State var portalPosition: CGPoint = .zero
    @State var dragOffset: CGSize = .zero
    @State var isDragging: Bool = false
    @State var isDraggingMesh: Bool = false
    @State var isWiring: Bool = false
    
    //zooming
    @State var zoomScale: CGFloat = 1.0
    @State var initialZoomScale: CGFloat?
    @State var initialPortalPosition: CGPoint?
    
    @GestureState private var gestureState: CGPoint = .zero
    
    @State private var shapeIndex = -1
    
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    
    
    
    //    @State var whereAt: CGPoint = .zero
    @State var frame: CGRect = .zero
    
    var body: some View {
        let shapeIndex = Binding<Int> (
            get: {
                self.shapeIndex
            },
            set: {
                self.shapeIndex = $0
                //                if let cell = self.cellData.selectedCell {
                //                    let index = self.cellData.indexOf(cell: cell)
                //                    let shapeType = ShapeType.allCases[self.shapeIndex]
                //                    self.cellData.cells[index].update(shapeType: shapeType)
                //                }
            })
        
        return VStack {
            PortalPositionView(
                portalPosition: $portalPosition,
                dragOffset: $dragOffset,
                zoomScale: $zoomScale,
                whereAt: $selection.whereAt,
                frame: $frame
            )
            SelectionHandlerView(selection: selection)
            TextField("Breathe…", text: self.$selection.editingText, onCommit: {
                if let node = self.selection.onlySelectedNode(in: self.mesh) {
                    self.mesh.updateNodeText(node, string: self.self.selection.editingText)
                }
            }).padding()
            
            GeometryReader { proxy in
                ZStack{
                    GridCompleteView(size: mesh.meshGranularity * zoomScale)
                    MouseLocationView(onMove: pointerCallback)
                    Rectangle().fill(Color.orange).opacity(0.2)
                    
                    MapView(selection: self.selection, mesh: self.mesh)
                        .scaleEffect(self.zoomScale)
                        .offset(x: self.portalPosition.x + self.dragOffset.width,
                                y: self.portalPosition.y + self.dragOffset.height)
                    
                    if self.isWiring {
                        SimplePathView(start: selection.startLocation, end: selection.draggingLocation)
                            .zIndex(1)
                    }
                }
                .coordinateSpace(name: meshCoordinateSpace)
                
                //.drawingGroup(opaque: true, colorMode: .extendedLinear) // this gives the No Entry Sign
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named(meshCoordinateSpace))
                    .updating($gestureState) {(value, state, transaction) in
                        state = value.location
                    }
                    .onChanged { value in
                        self.processDragChange(value, containerSize: proxy.size)
                    }
                    .onEnded { value in
                        self.processDragEnd(value, containerSize: proxy.size)
                    })
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            if self.initialZoomScale == nil {
                                self.initialZoomScale = self.zoomScale
                                self.initialPortalPosition = self.portalPosition
                            }
                            self.processScaleChange(value)
                        }
                        .onEnded { value in
                            self.processScaleChange(value)
                            self.initialZoomScale = nil
                            self.initialPortalPosition  = nil
                        }
                )
                .onTapGesture {
                    self.selection.unSelectNodes()
                }
                .contextMenu{
//                    Button("♥️ - Hearts", action: {
//                        print("selectHearts\(proxy.size)")
//                        addNewNode(mesh: mesh, whereAt: selection.whereAt, containerSize: proxy.size, portalPosition: portalPosition, zoomScale: zoomScale, payload: nil)
//                    })
                    Button("♣️ - Clubs", action: {
                        self.selection.showShapes.toggle()
                    })
                    Button("♠️ - Spades", action: selectSpades)
                    Button("♦️ - Diamonds", action: selectDiamonds)
                }
                
                .sheet(isPresented: self.$selection.showShapes)
                {
                    ComponentsGridView(selectedIndex: shapeIndex, audioUnitComponents: audioUnitComponents)
                    //.frame(width: min(geometry.size.width - 100, 300))
                        .frame(minWidth:600, minHeight: 400)
                        .onDisappear {
                            //print("Gone:\($shapeIndex)")
                            if self.shapeIndex >= 0 {
                                let component = audioUnitComponents.audioUnitComponents[self.shapeIndex]
                                component.instantiateComponent() { result in
                                    switch result {
                                case .success(let au):
                                        addNewNode(mesh: mesh, whereAt: selection.whereAt, containerSize: proxy.size, portalPosition: portalPosition, zoomScale: zoomScale, payload: au)
                                case .failure(let error):
                                    logger.log("Unable to select audio unit: \(String(describing: error))")
                                }
                                    self.shapeIndex = -1
                                }
                            }
                        }
                }
                //HorizontalUnitView(audioUnitComponents: audioUnitComponents)
                
                
            }
        }
    }
    
    func addNewNode(mesh: Mesh, whereAt: CGPoint, containerSize: CGSize, portalPosition: CGPoint, zoomScale: CGFloat, payload: AUManagedUnit?) {
        let p = mesh.meshCoordinates(whereAt: whereAt, containerSize: containerSize, portalPosition: portalPosition, zoomScale: zoomScale)
        let node = NodeBase(text: "child x:\(p.x) y:\(p.y)", position: p, payload: payload)
        mesh.addNode(node)
    }
    
    func pointerCallback(_ point: NSPoint, bounds: CGRect) {
        self.frame = bounds
        self.selection.whereAt = CGPoint(x: point.x, y: bounds.height-point.y)
    }
    
    static func restore() -> Mesh {
        let proxy = StorageHandler().restore()
        let mesh = Mesh(storage: proxy)
        return mesh
    }
    
}

//struct SurfaceView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mesh = Mesh.sampleMesh()
//        let selection = SelectionHandler()
//        return SurfaceView(mesh: mesh, selection: selection)
//    }
//}

extension SurfaceView {
    
    func distanceFrom(_ pointA: CGPoint, to pointB: CGPoint) -> CGFloat {
        let xdelta = pow(pointA.x - pointB.x,2)
        let ydelta = pow(pointA.y - pointB.y,2)
        
        return sqrt(xdelta + ydelta)
    }
    
    func hitTestNode(point: CGPoint, parent: CGSize) -> NodeBase? {
        for node in mesh.nodes {
            
            //let endPoint = transformedTo(position: node.position, parent: parent, portalPosition: portalPosition )
            let endPoint = node.transformedAndScaledNode(parent: parent, portalPosition: portalPosition, zoomScale: self.zoomScale )
            let dist =  distanceFrom(point, to: endPoint) / self.zoomScale
            if dist < node.size.width/2.0 {
                return node
            }
        }
        return nil
    }
    
    func hitTestPort(point: CGPoint, parent: CGSize ) -> PortBase? {
        for node in mesh.nodes {
            for port in node.ports {
                //let endPoint = port.position.transformedAndScaledPort(parent: parent, portalPosition: portalPosition, zoomScale: self.zoomScale )
                let endPoint = port.transformedAndScaledPort(parent: parent, portalPosition: portalPosition, zoomScale: self.zoomScale )
                let dist =  distanceFrom(point, to: endPoint) / self.zoomScale
                if dist < port.size.height/2 {
                    isWiring = true
                    return port
                }
            }
        }
        return nil
    }
    
    func processNodeTranslation(_ translation: CGSize, snapToGrid: Bool = false) {
        guard selection.draggingNodes.isEmpty == false else {
            return
        }
        let scaledTranslation = translation.scaledDownTo(self.zoomScale)
        mesh.processNodeTranslation(scaledTranslation,
                                    nodes: selection.draggingNodes,
                                    snapToGrid: snapToGrid)
    }
    
    func processDragChange(_ value: DragGesture.Value,
                           containerSize: CGSize) {
        if isDragging == false {
            isDragging = true
            selection.startLocation = value.startLocation
            if let port = self.hitTestPort(point: value.startLocation, parent: containerSize) {
                selection.firstWirePort = port
                
                isDraggingMesh = false
                isWiring = true
            } else if !isWiring {
                if let node = self.hitTestNode(point: value.startLocation, parent: containerSize) {
                    isDraggingMesh = false
                    selection.selectNode(node)
                    selection.startDragging(mesh)
                } else {
                    isDraggingMesh = true
                }
            }
        }
        
        if isDraggingMesh {
            self.dragOffset = value.translation
            selection.draggingLocation = value.location
        } else if isWiring {
            selection.draggingLocation = value.location
        } else {
            processNodeTranslation(value.translation, snapToGrid: mesh.snapToGrid)
        }
    }
    
    func processDragEnd(_ value: DragGesture.Value, containerSize: CGSize) {
        isDragging = false
        dragOffset = .zero
        
        selection.draggingLocation = value.location
        
        if isDraggingMesh {
            self.portalPosition = CGPoint(x: self.portalPosition.x + value.translation.width,
                                          y: self.portalPosition.y + value.translation.height)
        } else if isWiring {
            if let port = self.hitTestPort(point: value.location,
                                           parent: containerSize) {
                isDraggingMesh = false
                isWiring = true
                selection.secondWirePort = port
                if let first = selection.firstWirePort, let second = selection.secondWirePort {
                    if first != second {
                        mesh.connect(first, to: second)
                    } else {
                        print("Can't wire a port to itself")
                    }
                }
                selection.firstWirePort = nil
                selection.secondWirePort = nil
                
            } else {
                print("No Wiring Point in sight")
            }
        } else {
            processNodeTranslation(value.translation, snapToGrid: mesh.snapToGrid)
            selection.stopDragging(mesh)
        }
        isWiring = false
    }
    
}

extension SurfaceView {
    func scaledOffset(_ scale: CGFloat, initialValue: CGPoint) -> CGPoint {
        let newx = initialValue.x*scale
        let newy = initialValue.y*scale
        return CGPoint(x: newx, y: newy)
    }
    
    func clampedScale(_ scale: CGFloat, initialValue: CGFloat?) -> (scale: CGFloat, didClamp: Bool) {
        let minScale: CGFloat = 0.5
        let maxScale: CGFloat = 2.0
        let raw = scale.magnitude * (initialValue ?? maxScale)
        let value =  max(minScale, min(maxScale, raw))
        let didClamp = raw != value
        return (value, didClamp)
    }
    
    func processScaleChange(_ value: CGFloat) {
        let clamped = self.clampedScale(value, initialValue: self.initialZoomScale)
        self.zoomScale = clamped.scale
        if clamped.didClamp == false, let point = self.initialPortalPosition {
            self.portalPosition = self.scaledOffset(value, initialValue: point)
        }
    }
}
