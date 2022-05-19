// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation
import CryptoKit

extension AVAudioPCMBuffer {

    /// Add to an existing buffer
    ///
    /// - Parameter buffer: Buffer to append
    public func append(_ buffer: AVAudioPCMBuffer) {
        self.append(buffer, startingFrame: 0, frameCount: buffer.frameLength)
    }

    /// Add to an existing buffer with specific starting frame and size
    /// - Parameters:
    ///   - buffer: Buffer to append
    ///   - startingFrame: Starting frame location
    ///   - frameCount: Number of frames to append
    public func append(_ buffer: AVAudioPCMBuffer,
                       startingFrame: AVAudioFramePosition,
                       frameCount: AVAudioFrameCount) {
        precondition(format == buffer.format,
                     "Format mismatch")
        precondition(startingFrame + AVAudioFramePosition(frameCount) <= AVAudioFramePosition(buffer.frameLength),
                     "Insufficient audio in buffer")
        precondition(frameLength + frameCount <= frameCapacity,
                     "Insufficient space in buffer")

        let dst1 = floatChannelData![0]
        let src1 = buffer.floatChannelData![0]
        
        memcpy(dst1.advanced(by: stride * Int(frameLength)),
               src1.advanced(by: stride * Int(startingFrame)),
               Int(frameCount) * stride * MemoryLayout<Float>.size)

        let dst2 = floatChannelData![1]
        let src2 = buffer.floatChannelData![1]

        memcpy(dst2.advanced(by: stride * Int(frameLength)),
               src2.advanced(by: stride * Int(startingFrame)),
               Int(frameCount) * stride * MemoryLayout<Float>.size)

        frameLength += frameCount
    }

    /// Copies data from another PCM buffer.  Will copy to the end of the buffer (frameLength), and
    /// increment frameLength. Will not exceed frameCapacity.
    ///
    /// - Parameter buffer: The source buffer that data will be copied from.
    /// - Parameter readOffset: The offset into the source buffer to read from.
    /// - Parameter frames: The number of frames to copy from the source buffer.
    /// - Returns: The number of frames copied.
    @discardableResult public func copy(from buffer: AVAudioPCMBuffer,
                                        readOffset: AVAudioFrameCount = 0,
                                        frames: AVAudioFrameCount = 0) -> AVAudioFrameCount {
        let remainingCapacity = frameCapacity - frameLength
        if remainingCapacity == 0 {
            Log("AVAudioBuffer copy(from) - no capacity!")
            return 0
        }

        if format != buffer.format {
            Log("AVAudioBuffer copy(from) - formats must match!")
            return 0
        }

        let totalFrames = Int(min(min(frames == 0 ? buffer.frameLength : frames, remainingCapacity),
                                  buffer.frameLength - readOffset))

        if totalFrames <= 0 {
            Log("AVAudioBuffer copy(from) - No frames to copy!")
            return 0
        }

        let frameSize = Int(format.streamDescription.pointee.mBytesPerFrame)
        if let src = buffer.floatChannelData,
           let dst = floatChannelData {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else if let src = buffer.int16ChannelData,
                  let dst = int16ChannelData {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else if let src = buffer.int32ChannelData,
                  let dst = int32ChannelData {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else {
            return 0
        }
        frameLength += AVAudioFrameCount(totalFrames)
        return AVAudioFrameCount(totalFrames)
    }


    /// Extract a portion of the buffer
    /// 
    /// - Parameter startTime: The time of the in point of the extraction
    /// - Parameter endTime: The time of the out point
    /// - Returns: A new edited AVAudioPCMBuffer
    public func extract(from startTime: TimeInterval,
                        to endTime: TimeInterval) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let startSample = AVAudioFrameCount(startTime * sampleRate)
        var endSample = AVAudioFrameCount(endTime * sampleRate)

        if endSample == 0 {
            endSample = frameLength
        }

        let frameCapacity = endSample - startSample

        guard frameCapacity > 0 else {
            Log("startSample must be before endSample", type: .error)
            return nil
        }

        guard let editedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            Log("Failed to create edited buffer", type: .error)
            return nil
        }

        guard editedBuffer.copy(from: self, readOffset: startSample, frames: frameCapacity) > 0 else {
            Log("Failed to write to edited buffer", type: .error)
            return nil
        }

        return editedBuffer
    }
}
