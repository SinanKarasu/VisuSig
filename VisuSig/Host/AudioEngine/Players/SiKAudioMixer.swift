//
//  AudioMixer.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/3/22.
//

import Foundation

import SwiftUI
import AVFoundation

class SiKAudioMixer {
    let engine = AVAudioEngine()
    let player = AVAudioPlayer()
    let drumPlayer = AVAudioPlayerNode()
    let bassPlayer = AVAudioPlayerNode()
    let keysPlayer = AVAudioPlayerNode()
    let clickPlayer = AVAudioPlayerNode()
    let mixer = AVAudioMixerNode()


    init() {
        if let drumAudioPath = Bundle.main.path(forResource: "Drums1", ofType: "mp3") {
            let drumsAudioUrl = URL(fileURLWithPath: drumAudioPath)
            let drumsAudioFile = try? AVAudioFile(forReading: drumsAudioUrl)
            engine.connect(drumPlayer, to: mixer, format: drumsAudioFile?.processingFormat)
            drumPlayer.scheduleFile(drumsAudioFile!, at: nil, completionHandler: nil)
        }
        drumPlayer.play()
        engine.attach(drumPlayer)


        if let bassAudioPath = Bundle.main.path(forResource: "Bass1", ofType: "mp3") {
            let bassAudioUrl = URL(fileURLWithPath: bassAudioPath)
            let bassAudioFile = try? AVAudioFile(forReading: bassAudioUrl)
            engine.connect(bassPlayer, to: mixer, format: bassAudioFile?.processingFormat)
            bassPlayer.scheduleFile(bassAudioFile!, at: nil, completionHandler: nil)
        }
        bassPlayer.play()
        engine.attach(bassPlayer)


        if let keysAudioPath = Bundle.main.path(forResource: "Keys1", ofType: "mp3") {
            let keysAudioUrl = URL(fileURLWithPath: keysAudioPath)
            let keysAudioFile = try? AVAudioFile(forReading: keysAudioUrl)
            engine.connect(keysPlayer, to: mixer, format: keysAudioFile?.processingFormat)
            keysPlayer.scheduleFile(keysAudioFile!, at: nil, completionHandler: nil)
        }
        keysPlayer.play()
        engine.attach(keysPlayer)


        if let clickAudioPath = Bundle.main.path(forResource: "Click1", ofType: "mp3") {
            let clickAudioUrl = URL(fileURLWithPath: clickAudioPath)
            let clickAudioFile = try? AVAudioFile(forReading: clickAudioUrl)
            engine.connect(clickPlayer, to: mixer, format: clickAudioFile?.processingFormat)
            clickPlayer.scheduleFile(clickAudioFile!, at: nil, completionHandler: nil)
        }
        clickPlayer.play()
        engine.attach(clickPlayer)

        engine.attach(mixer)

        engine.prepare()
        do {
            try engine.start()
        } catch {
            print(error.localizedDescription)
        }
    }
}
