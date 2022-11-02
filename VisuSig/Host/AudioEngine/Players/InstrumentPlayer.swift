//
//  InstrumentPlayer.swift
//  SiKAUv3HostRedo
//
//  Created by Sinan Karasu on 1/26/22.
//

import Foundation
import AVFoundation

class InstrumentPlayer {
    private var isPlaying = false
    private var isDone = false
    private var noteBlock: AUScheduleMIDIEventBlock

    init?(audioUnit: AUAudioUnit?) {
        guard let audioUnit = audioUnit else { return nil }
        guard let theNoteBlock = audioUnit.scheduleMIDIEventBlock else { return nil }
        noteBlock = theNoteBlock
    }

    func play() {
        if !isPlaying {
            isDone = false
            scheduleInstrumentLoop()
        }
    }

    @discardableResult
    func stop() -> Bool {
        isPlaying = false
        synced(isDone) {}
        return isDone
    }

    private func synced(_ lock: Any, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }

    private func scheduleInstrumentLoop() {
        isPlaying = true

        let cbytes = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)

        DispatchQueue.global(qos: .default).async {
            var step = 0

            // The steps arrays define the musical intervals of a scale (w = whole step, h = half step).

            // C Major: w, w, h, w, w, w, h
            let steps = [2, 2, 1, 2, 2, 2, 1]

            // C Minor: w, h, w, w, w, h, w
            // let steps = [2, 1, 2, 2, 2, 1, 2]

            // C Lydian: w, w, w, h, w, w, h
            // let steps = [2, 2, 2, 1, 2, 2, 1]

            cbytes[0] = 0xB0 // status
            cbytes[1] = 60 // note
            cbytes[2] = 0 // velocity
            self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

            usleep(useconds_t(0.5))

            var releaseTime: Float = 0.05

            usleep(useconds_t(0.1 * 1e6))

            var note = 0
            self.synced(self.isDone) {
                while self.isPlaying {
                    // lengthen the releaseTime by 5% each time up to 10 seconds.
                    if releaseTime < 10.0 {
                        releaseTime = min(releaseTime * 1.05, 10.0)
                    }

                    cbytes[0] = 0x90
                    cbytes[1] = UInt8(60 + note)
                    cbytes[2] = 64
                    self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

                    usleep(useconds_t(0.2 * 1e6))

                    cbytes[2] = 0    // note off
                    self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

                    // Reset the note and step after a 2-octave run. (12 semi-tones * 2)
                    if note >= 24 {
                        note = 0
                        step = 0
                        continue
                    }

                    // Increment the note interval to the next interval step in the scale
                    note += steps[step]

                    step += 1

                    if step >= steps.count {
                        step = 0
                    }
                } // while isPlaying

                cbytes[0] = 0xB0
                cbytes[1] = 60
                cbytes[2] = 0
                self.noteBlock(AUEventSampleTimeImmediate, 0, 3, cbytes)

                self.isDone = true

                cbytes.deallocate()
            }
        }
    }
}
