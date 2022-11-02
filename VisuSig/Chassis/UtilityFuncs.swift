//
//  UtilityFuncs.swift
//  AVLavLib
//
//  Created by Sinan Karasu on 9/8/20.
//

import Foundation
import AudioToolbox

///  Create a String from an encoded 4char.
///
///  - parameter status: an `OSStatus` containing the encoded 4char.
///
///  - returns: The String representation.


@discardableResult func checkError(status: OSStatus, mess: String) -> OSStatus {
    if status == noErr {
        return status
    }
    print("Status: \(status.detailedErrorMessage() ?? String(describing: status.asString()))")
    return status
}

let isDebug = true

// **************************
// OSStatus extensions for logging
// **************************
extension OSStatus {
    // **************************
    func asString() -> String? {
        let n = UInt32(bitPattern: self.littleEndian)
        guard let n1 = UnicodeScalar((n >> 24) & 255), n1.isASCII else { return nil }
        guard let n2 = UnicodeScalar((n >> 16) & 255), n2.isASCII else { return nil }
        guard let n3 = UnicodeScalar((n >> 8) & 255), n3.isASCII else { return nil }
        guard let n4 = UnicodeScalar( n & 255), n4.isASCII else { return nil }
        return String(n1) + String(n2) + String(n3) + String(n4)
    } // asString

    // **************************
    func detailedErrorMessage() -> String? {
        switch self {
        case 0: return "Success"
            // ***** AUGraph errors
            // AVAudioRecorder errors
        case kAudioFileUnspecifiedError:
            return "kAudioFileUnspecifiedError"

        case kAudioFileUnsupportedFileTypeError:
            return "kAudioFileUnsupportedFileTypeError"

        case kAudioFileUnsupportedDataFormatError:
            return "kAudioFileUnsupportedDataFormatError"

        case kAudioFileUnsupportedPropertyError:
            return "kAudioFileUnsupportedPropertyError"

        case kAudioFileBadPropertySizeError:
            return "kAudioFileBadPropertySizeError"

        case kAudioFilePermissionsError:
            return "kAudioFilePermissionsError"

        case kAudioFileNotOptimizedError:
            return "kAudioFileNotOptimizedError"

        case kAudioFileInvalidChunkError:
            return "kAudioFileInvalidChunkError"

        case kAudioFileDoesNotAllow64BitDataSizeError:
            return "kAudioFileDoesNotAllow64BitDataSizeError"

        case kAudioFileInvalidPacketOffsetError:
            return "kAudioFileInvalidPacketOffsetError"

        case kAudioFileInvalidFileError:
            return "kAudioFileInvalidFileError"

        case kAudioFileOperationNotSupportedError:
            return "kAudioFileOperationNotSupportedError"

        case kAudioFileNotOpenError:
            return "kAudioFileNotOpenError"

        case kAudioFileEndOfFileError:
            return "kAudioFileEndOfFileError"

        case kAudioFilePositionError:
            return "kAudioFilePositionError"

        case kAudioFileFileNotFoundError:
            return "kAudioFileFileNotFoundError"

            // ***** AUGraph errors
        case kAUGraphErr_NodeNotFound:             return "AUGraph Node Not Found"
        case kAUGraphErr_InvalidConnection:        return "AUGraph Invalid Connection"
        case kAUGraphErr_OutputNodeErr:            return "AUGraph Output Node Error"
        case kAUGraphErr_CannotDoInCurrentContext: return "AUGraph Cannot Do In Current Context"
        case kAUGraphErr_InvalidAudioUnit:         return "AUGraph Invalid Audio Unit"

            // ***** MIDI errors
        case kMIDIInvalidClient:     return "MIDI Invalid Client"
        case kMIDIInvalidPort:       return "MIDI Invalid Port"
        case kMIDIWrongEndpointType: return "MIDI Wrong Endpoint Type"
        case kMIDINoConnection:      return "MIDI No Connection"
        case kMIDIUnknownEndpoint:   return "MIDI Unknown Endpoint"
        case kMIDIUnknownProperty:   return "MIDI Unknown Property"
        case kMIDIWrongPropertyType: return "MIDI Wrong Property Type"
        case kMIDINoCurrentSetup:    return "MIDI No Current Setup"
        case kMIDIMessageSendErr:    return "MIDI Message Send Error"
        case kMIDIServerStartErr:    return "MIDI Server Start Error"
        case kMIDISetupFormatErr:    return "MIDI Setup Format Error"
        case kMIDIWrongThread:       return "MIDI Wrong Thread"
        case kMIDIObjectNotFound:    return "MIDI Object Not Found"
        case kMIDIIDNotUnique:       return "MIDI ID Not Unique"
        case kMIDINotPermitted:      return "MIDI Not Permitted"

            // ***** AudioToolbox errors
        case kAudioToolboxErr_CannotDoInCurrentContext: return "AudioToolbox Cannot Do In Current Context"
        case kAudioToolboxErr_EndOfTrack:               return "AudioToolbox End Of Track"
        case kAudioToolboxErr_IllegalTrackDestination:  return "AudioToolbox Illegal Track Destination"
        case kAudioToolboxErr_InvalidEventType:         return "AudioToolbox Invalid Event Type"
        case kAudioToolboxErr_InvalidPlayerState:       return "AudioToolbox Invalid Player State"
        case kAudioToolboxErr_InvalidSequenceType:      return "AudioToolbox Invalid Sequence Type"
        case kAudioToolboxErr_NoSequence:               return "AudioToolbox No Sequence"
        case kAudioToolboxErr_StartOfTrack:             return "AudioToolbox Start Of Track"
        case kAudioToolboxErr_TrackIndexError:          return "AudioToolbox Track Index Error"
        case kAudioToolboxErr_TrackNotFound:            return "AudioToolbox Track Not Found"
        case kAudioToolboxError_NoTrackDestination:     return "AudioToolbox No Track Destination"

            // ***** AudioUnit errors
        case kAudioUnitErr_CannotDoInCurrentContext: return "AudioUnit Cannot Do In Current Context"
        case kAudioUnitErr_FailedInitialization:     return "AudioUnit Failed Initialization"
        case kAudioUnitErr_FileNotSpecified:         return "AudioUnit File Not Specified"
        case kAudioUnitErr_FormatNotSupported:       return "AudioUnit Format Not Supported"
        case kAudioUnitErr_IllegalInstrument:        return "AudioUnit Illegal Instrument"
        case kAudioUnitErr_Initialized:              return "AudioUnit Initialized"
        case kAudioUnitErr_InvalidElement:           return "AudioUnit Invalid Element"
        case kAudioUnitErr_InvalidFile:              return "AudioUnit Invalid File"
        case kAudioUnitErr_InvalidOfflineRender:     return "AudioUnit Invalid Offline Render"
        case kAudioUnitErr_InvalidParameter:         return "AudioUnit Invalid Parameter"
        case kAudioUnitErr_InvalidProperty:          return "AudioUnit Invalid Property"
        case kAudioUnitErr_InvalidPropertyValue:     return "AudioUnit Invalid Property Value"
        case kAudioUnitErr_InvalidScope:             return "AudioUnit InvalidScope"
        case kAudioUnitErr_InstrumentTypeNotFound:   return "AudioUnit Instrument Type Not Found"
        case kAudioUnitErr_NoConnection:             return "AudioUnit No Connection"
        case kAudioUnitErr_PropertyNotInUse:         return "AudioUnit Property Not In Use"
        case kAudioUnitErr_PropertyNotWritable:      return "AudioUnit Property Not Writable"
        case kAudioUnitErr_TooManyFramesToProcess:   return "AudioUnit Too Many Frames To Process"
        case kAudioUnitErr_Unauthorized:             return "AudioUnit Unauthorized"
        case kAudioUnitErr_Uninitialized:            return "AudioUnit Uninitialized"
        case kAudioUnitErr_UnknownFileType:          return "AudioUnit Unknown File Type"
        case kAudioUnitErr_RenderTimeout:             return "AudioUnit Rendre Timeout"

            // ***** Audio errors
        case kAudio_BadFilePathError:      return "Audio Bad File Path Error"
        case kAudio_FileNotFoundError:     return "Audio File Not Found Error"
        case kAudio_FilePermissionError:   return "Audio File Permission Error"
        case kAudio_MemFullError:          return "Audio Mem Full Error"
        case kAudio_ParamError:            return "Audio Param Error"
        case kAudio_TooManyFilesOpenError: return "Audio Too Many Files Open Error"
        case kAudio_UnimplementedError:    return "Audio Unimplemented Error"

        default: return "Unknown error (no description)"
        } // switch(self)
    } // detailedErrorMessage

    // **************************
    func debugLog(filePath: String = #file, line: Int = #line, funcName: String = #function) {
        guard isDebug, self != noErr else { return }
        let fileComponents = filePath.components(separatedBy: "/")
        let fileName = fileComponents.last ?? "???"

        var logString = "OSStatus = \(self) in \(fileName) - \(funcName), line \(line)"

        if let errorMessage = self.detailedErrorMessage() { logString = errorMessage + ", " + logString } else if let errorCode = self.asString() { logString = errorCode + ", " + logString }

        NSLog(logString)
    } // debugLog
} // extension OSStatus


// Utility Functions

// func checkError(error:OSStatus, operation: String){
//    func fourCCToStringVer2(_ value: FourCharCode) -> String {
//        // sik: Look into possible CFSwapInt32HostToBig here. The following must be swapped end to end
//        let utf16 = [
//            UInt16((value >> 24) & 0xFF),
//            UInt16((value >> 16) & 0xFF),
//            UInt16((value >> 8) & 0xFF),
//            UInt16((value & 0xFF)) ]
//        if isprint(Int32(utf16[0])) > 0 &&
//            isprint(Int32(utf16[0])) > 0 &&
//            isprint(Int32(utf16[0])) > 0 &&
//            isprint(Int32(utf16[0])) > 0 {
//            return "'" + String(utf16CodeUnits: utf16, count: 4) + "'"
//        } else {
//            return "\(error)"
//        }
//    }
//
//    if error == noErr { return }
//    let dummy:String = fourCCToStringVer2(FourCharCode(error))
//    print ("Error: \(dummy)")
//    exit(1)
//
// }


// func fourCharCodeFrom(string : String) -> FourCharCode
// {
//    assert(string.count == 4, "String length must be 4")
//    var result : FourCharCode = 0
//    for char in string.utf16 {
//        result = (result << 8) + FourCharCode(char)
//    }
//    return result
// }

// func fourCharCodeSwiftier(from string : String) -> FourCharCode
// {
//    return string.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
// }
