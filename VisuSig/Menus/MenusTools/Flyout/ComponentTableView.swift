//
//  ComponentGridView.swift
//  ComponentGridView
//
//  Created by Sinan Karasu on 8/29/21.
//

import SwiftUI
import AVFoundation

struct MyArray: View {
    var texts: [String]
    @State var showPopUp = false
    var body: some View {
        return Button("\(texts.count)") {
            showPopUp.toggle()
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.cyan)
        .sheet(isPresented: $showPopUp) {
            VStack {
                Button("Button") {
                    showPopUp.toggle()
                }
                // SheetView(isVisible: self.$sheetIsShowing, myLayout: myLayout)
                ForEach(texts, id: \.self) { text in
                    Text(text)
                }
            }
        }
    }
}

struct MyButton: View {
    var text: String
    var body: some View {
        return Button(text) {
            print("hello")
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.cyan)
    }
}

func myIcon(img: NSImage?) -> some View {
    if let x = img {
        return Image(nsImage: x)
    } else {
        return Image(systemName: "waveform.and.mic")
    }
}

struct ComponentTableView: View {
    // @Environment(\.presentationMode) var presentationMode
    @Binding var selectedIndex: Int

    @State private var selection: UUID?

    @State private var order: [KeyPathComparator<Component>] = [
        .init(\.nameAndMFG, order: SortOrder.forward)
    ]

    var audioUnitComponents: AudioUnitComponents
    @ObservedObject var selectionHandler: SelectionHandler

    var selectedUnit: String {
        guard let selection = selection else {
            return "no selection"
        }

        let event = audioUnitComponents.audioUnitComponents.first {
            $0.id == selection
        }
        return event!.nameAndMFG
    }

    var selectedComponent: Component {
        let event = audioUnitComponents.audioUnitComponents.first {
            $0.id == selection
        }
        return event!
    }

    var body: some View {
        VStack {
            HStack {
                Text("SELECTION: ").foregroundColor(.red) + Text(selectedUnit)
                Button("Choose") {
                    self.selectionHandler.showShapes = false
                    selectedIndex = audioUnitComponents.audioUnitComponents.firstIndex(of: selectedComponent)!
                }
                Button("Cancel") {
                    self.selectionHandler.showShapes = false
                }
            }

            Text("Entries:\(audioUnitComponents.audioUnitComponents.count)")

            Table(audioUnitComponents.audioUnitComponents, selection: $selection) {
                TableColumn("Name") { Text($0.name) } // .width(min: 35, ideal: 35, max:   60)
                TableColumn("Mfg", value: \.mfg) // {viewOfStr($0.avAudioUnitComponent?.manufacturerName)} //.width(min: 35, ideal: 35, max:   60)
                // TableColumn("Icon") { myIcon(img: $0.avAudioUnitComponent?.icon)}
                TableColumn("Type") { viewOfStr($0.avAudioUnitComponent?.typeName) } // .width(min: 35, ideal: 35, max:   60)
                TableColumn("All Tag\nCount") { viewOfStr("\($0.avAudioUnitComponent?.allTagNames.count ?? 0)") } // .width(min: 35, ideal: 35, max:   60)
                TableColumn("All\nTags") { allTags(texts: $0.avAudioUnitComponent) } // .width(min: 35, ideal: 35, max:   60)
                TableColumn("User\nTags") { userTags(texts: $0.avAudioUnitComponent) } // .width(min: 35, ideal: 35, max:   60)
                TableColumn("Custom\nView") { viewOfBool($0.avAudioUnitComponent?.hasCustomView)   }.width(min: 35, ideal: 35, max: 60)
                TableColumn("MIDI\nInput") { viewOfBool($0.avAudioUnitComponent?.hasMIDIInput) }.width(min: 35, ideal: 35, max: 60)
                TableColumn("MIDI\nOutput") { viewOfBool($0.avAudioUnitComponent?.hasMIDIOutput) }.width(min: 35, ideal: 35, max: 60)
                TableColumn("PASS\nAUVal") { viewOfBool($0.avAudioUnitComponent?.passesAUVal) }.width(min: 35, ideal: 35, max: 60)
            }
        }
        .frame(width: 800, height: 800)
    }

    func allTags(texts: AVAudioUnitComponent?)-> some View {
        if let texts = texts {
            return MyArray(texts: texts.allTagNames)
        }
        return MyArray(texts: ["Hello There"])
    }

    func userTags(texts: AVAudioUnitComponent?)-> some View {
        if let texts = texts {
            return MyArray(texts: texts.userTagNames)
        }
        return MyArray(texts: ["Hello There"])
    }

    func myArray(texts: [String])-> some View {
        return MyArray(texts: texts)
    }
    func viewOfBool(_ val: Bool?) -> some View {
        if let val = val {
            return Text(val ? "Y" : "N")
        } else {
            return Text("unknown")
        }
    }

    func viewOfStr(_ val: String?) -> some View {
        if let val = val {
            return Text(val)
        } else {
            return Text("unknown")
        }
    }
}


// struct ComponentTableView_Previews: PreviewProvider {
//    @State static var selectedIndex: Int = 1
//    @State static var audioUnitComponents = AudioUnitComponents()
//
//    static var previews: some View {
//        ComponentTableView(audioUnitComponents: audioUnitComponents, selectionHandler: SelectionHandler())
//    }
// }
