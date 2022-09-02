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


@discardableResult func checkError(status: OSStatus, mess: String) -> OSStatus{
    
    if status == noErr {
        return status
    }
    
    let s = status.asString()
    print("error chars '\(String(describing: s))'")
    
    
    switch status {
        // AudioToolbox
    case kAUGraphErr_NodeNotFound:
        print("kAUGraphErr_NodeNotFound")
        
    case kAUGraphErr_OutputNodeErr:
        print("kAUGraphErr_OutputNodeErr")
        
    case kAUGraphErr_InvalidConnection:
        print("kAUGraphErr_InvalidConnection")
        
    case kAUGraphErr_CannotDoInCurrentContext:
        print("kAUGraphErr_CannotDoInCurrentContext")
        
    case kAUGraphErr_InvalidAudioUnit:
        print("kAUGraphErr_InvalidAudioUnit")
        
    case kMIDIInvalidClient :
        print("kMIDIInvalidClient ")
        
        
    case kMIDIInvalidPort :
        print("kMIDIInvalidPort ")
        
        
    case kMIDIWrongEndpointType :
        print("kMIDIWrongEndpointType")
        
        
    case kMIDINoConnection :
        print("kMIDINoConnection ")
        
        
    case kMIDIUnknownEndpoint :
        print("kMIDIUnknownEndpoint ")
        
        
    case kMIDIUnknownProperty :
        print("kMIDIUnknownProperty ")
        
        
    case kMIDIWrongPropertyType :
        print("kMIDIWrongPropertyType ")
        
        
    case kMIDINoCurrentSetup :
        print("kMIDINoCurrentSetup ")
        
        
    case kMIDIMessageSendErr :
        print("kMIDIMessageSendErr ")
        
        
    case kMIDIServerStartErr :
        print("kMIDIServerStartErr ")
        
        
    case kMIDISetupFormatErr :
        print("kMIDISetupFormatErr ")
        
        
    case kMIDIWrongThread :
        print("kMIDIWrongThread ")
        
        
    case kMIDIObjectNotFound :
        print("kMIDIObjectNotFound ")
        
        
    case kMIDIIDNotUnique :
        print("kMIDIIDNotUnique ")
        
        
    case kAudioToolboxErr_InvalidSequenceType :
        print("kAudioToolboxErr_InvalidSequenceType ")
        
    case kAudioToolboxErr_TrackIndexError :
        print("kAudioToolboxErr_TrackIndexError ")
        
    case kAudioToolboxErr_TrackNotFound :
        print("kAudioToolboxErr_TrackNotFound ")
        
    case kAudioToolboxErr_EndOfTrack :
        print("kAudioToolboxErr_EndOfTrack ")
        
    case kAudioToolboxErr_StartOfTrack :
        print("kAudioToolboxErr_StartOfTrack ")
        
    case kAudioToolboxErr_IllegalTrackDestination:
        print("kAudioToolboxErr_IllegalTrackDestination")
        
    case kAudioToolboxErr_NoSequence :
        print("kAudioToolboxErr_NoSequence ")
        
    case kAudioToolboxErr_InvalidEventType    :
        print("kAudioToolboxErr_InvalidEventType")
        
    case kAudioToolboxErr_InvalidPlayerState:
        print("kAudioToolboxErr_InvalidPlayerState")
        
    case kAudioUnitErr_InvalidProperty    :
        print("kAudioUnitErr_InvalidProperty")
        
    case kAudioUnitErr_InvalidParameter    :
        print("kAudioUnitErr_InvalidParameter")
        
    case kAudioUnitErr_InvalidElement :
        print("kAudioUnitErr_InvalidElement")
        
    case kAudioUnitErr_NoConnection    :
        print("kAudioUnitErr_NoConnection")
        
    case kAudioUnitErr_FailedInitialization    :
        print("kAudioUnitErr_FailedInitialization")
        
    case kAudioUnitErr_TooManyFramesToProcess:
        print("kAudioUnitErr_TooManyFramesToProcess")
        
    case kAudioUnitErr_InvalidFile:
        print("kAudioUnitErr_InvalidFile")
        
    case kAudioUnitErr_FormatNotSupported :
        print("kAudioUnitErr_FormatNotSupported")
        
    case kAudioUnitErr_Uninitialized:
        print("kAudioUnitErr_Uninitialized")
        
    case kAudioUnitErr_InvalidScope :
        print("kAudioUnitErr_InvalidScope")
        
    case kAudioUnitErr_PropertyNotWritable :
        print("kAudioUnitErr_PropertyNotWritable")
        
    case kAudioUnitErr_InvalidPropertyValue :
        print("kAudioUnitErr_InvalidPropertyValue")
        
    case kAudioUnitErr_PropertyNotInUse :
        print("kAudioUnitErr_PropertyNotInUse")
        
    case kAudioUnitErr_Initialized :
        print("kAudioUnitErr_Initialized")
        
    case kAudioUnitErr_InvalidOfflineRender :
        print("kAudioUnitErr_InvalidOfflineRender")
        
    case kAudioUnitErr_Unauthorized :
        print("kAudioUnitErr_Unauthorized")
        
    case kAudioUnitErr_CannotDoInCurrentContext:
        print("kAudioUnitErr_CannotDoInCurrentContext")
        
    case kAudioUnitErr_FailedInitialization:
        print("kAudioUnitErr_FailedInitialization")
        
    case kAudioUnitErr_FileNotSpecified:
        print("kAudioUnitErr_FileNotSpecified")
        
    case kAudioUnitErr_FormatNotSupported:
        print("kAudioUnitErr_FormatNotSupported")
        
    case kAudioUnitErr_IllegalInstrument:
        print("kAudioUnitErr_IllegalInstrument")
        
    case kAudioUnitErr_Initialized:
        print("kAudioUnitErr_Initialized")
        
    case kAudioUnitErr_InstrumentTypeNotFound:
        print("kAudioUnitErr_InstrumentTypeNotFound")
        
    case kAudioUnitErr_InvalidElement:
        print("kAudioUnitErr_InvalidElement")
        
    case kAudioUnitErr_InvalidFile:
        print("kAudioUnitErr_InvalidFile")
        
    case kAudioUnitErr_InvalidOfflineRender:
        print("kAudioUnitErr_InvalidOfflineRender")
        
    case kAudioUnitErr_InvalidParameter:
        print("kAudioUnitErr_InvalidParameter")
        
    case kAudioUnitErr_InvalidProperty:
        print("kAudioUnitErr_InvalidProperty")
        
    case kAudioUnitErr_InvalidPropertyValue:
        print("kAudioUnitErr_InvalidPropertyValue")
        
    case kAudioUnitErr_InvalidScope:
        print("kAudioUnitErr_InvalidScope")
        
    case kAudioUnitErr_NoConnection:
        print("kAudioUnitErr_NoConnection")
        
    case kAudioUnitErr_PropertyNotInUse:
        print("kAudioUnitErr_PropertyNotInUse")
        
    case kAudioUnitErr_PropertyNotWritable:
        print("kAudioUnitErr_PropertyNotWritable")
        
    case kAudioUnitErr_TooManyFramesToProcess:
        print("kAudioUnitErr_TooManyFramesToProcess")
        
    case kAudioUnitErr_Unauthorized:
        print("kAudioUnitErr_Unauthorized")
        
    case kAudioUnitErr_Uninitialized:
        print("kAudioUnitErr_Uninitialized")
        
    case kAudioUnitErr_UnknownFileType:
        print("kAudioUnitErr_UnknownFileType")
        
    case kAudioComponentErr_InstanceInvalidated:
        print("kAudioComponentErr_InstanceInvalidated ")
        
    case kAudioComponentErr_DuplicateDescription:
        print("kAudioComponentErr_DuplicateDescription ")
        
    case kAudioComponentErr_UnsupportedType:
        print("kAudioComponentErr_UnsupportedType ")
        
    case kAudioComponentErr_TooManyInstances:
        print("kAudioComponentErr_TooManyInstances ")
        
    case kAudioComponentErr_NotPermitted:
        print("kAudioComponentErr_NotPermitted ")
        
    case kAudioComponentErr_InitializationTimedOut:
        print("kAudioComponentErr_InitializationTimedOut ")
        
    case kAudioComponentErr_InvalidFormat:
        print("kAudioComponentErr_InvalidFormat ")
        
        // in CoreAudioTypes
    case kAudio_UnimplementedError :
        print("kAudio_UnimplementedError")
        
    case kAudio_FileNotFoundError :
        print("kAudio_FileNotFoundError")
        
    case kAudio_FilePermissionError :
        print("kAudio_FilePermissionError")
        
    case kAudio_TooManyFilesOpenError :
        print("kAudio_TooManyFilesOpenError")
        
    case kAudio_BadFilePathError :
        print("kAudio_BadFilePathError")
        
    case kAudio_ParamError :
        print("kAudio_ParamError") // the infamous -50
        
    case kAudio_MemFullError :
        print("kAudio_MemFullError")
        
        
    default:
        print("huh?")
        print("bad status \(status)")
        //print("\(__LINE__) bad status \(error)")
    }
    return status
}

@discardableResult public func checkError2(error: OSStatus, operation: String) -> OSStatus {

    if (error == noErr) {
        return error
    }
    else if (error < 0) {
        print("OSStatus Error code less than zero")
        print("Error: \(error)")
    } else {
        let count = 5
        let stride = MemoryLayout<OSStatus>.stride
        let byteCount = stride * count

        var error_ =  CFSwapInt32HostToBig(UInt32(error))
        var charArray: [CChar] = [CChar](repeating: 0, count: byteCount )
        withUnsafeBytes(of: &error_) { (buffer: UnsafeRawBufferPointer) in
            for (index, byte) in buffer.enumerated() {
                charArray[index + 1] = CChar(byte)
            }
        }

        let v1 = charArray[1], v2 = charArray[2], v3 = charArray[3], v4 = charArray[4]

        if (isprint(Int32(v1)) > 0 && isprint(Int32(v2)) > 0 && isprint(Int32(v3)) > 0 && isprint(Int32(v4)) > 0) {
            charArray[0] = "\'".utf8CString[0]
            charArray[5] = "\'".utf8CString[0]
            let errStr = NSString(bytes: &charArray, length: charArray.count, encoding: String.Encoding.ascii.rawValue)
            print("Error: \(operation) (\(errStr!))")
        }
        else {
            print("Error: \(error)")
        }

    }
    
    exit(1)

}

let isDebug = true

//**************************
// OSStatus extensions for logging
//**************************
extension OSStatus {
    //**************************
    func asString() -> String? {
        let n = UInt32(bitPattern: self.littleEndian)
        guard let n1 = UnicodeScalar((n >> 24) & 255), n1.isASCII else { return nil }
        guard let n2 = UnicodeScalar((n >> 16) & 255), n2.isASCII else { return nil }
        guard let n3 = UnicodeScalar((n >>  8) & 255), n3.isASCII else { return nil }
        guard let n4 = UnicodeScalar( n        & 255), n4.isASCII else { return nil }
        return String(n1) + String(n2) + String(n3) + String(n4)
    } // asString
    
    //**************************
    func detailedErrorMessage() -> String? {
        switch(self) {
            //***** AUGraph errors
        case kAUGraphErr_NodeNotFound:             return "AUGraph Node Not Found"
        case kAUGraphErr_InvalidConnection:        return "AUGraph Invalid Connection"
        case kAUGraphErr_OutputNodeErr:            return "AUGraph Output Node Error"
        case kAUGraphErr_CannotDoInCurrentContext: return "AUGraph Cannot Do In Current Context"
        case kAUGraphErr_InvalidAudioUnit:         return "AUGraph Invalid Audio Unit"
            
            //***** MIDI errors
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
            
            //***** AudioToolbox errors
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
            
            //***** AudioUnit errors
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
            
            //***** AudioComponent errors
        case kAudioComponentErr_DuplicateDescription:   return "AudioComponent Duplicate Description"
        case kAudioComponentErr_InitializationTimedOut: return "AudioComponent Initialization Timed Out"
        case kAudioComponentErr_InstanceInvalidated:    return "AudioComponent Instance Invalidated"
        case kAudioComponentErr_InvalidFormat:          return "AudioComponent Invalid Format"
        case kAudioComponentErr_NotPermitted:           return "AudioComponent Not Permitted "
        case kAudioComponentErr_TooManyInstances:       return "AudioComponent Too Many Instances"
        case kAudioComponentErr_UnsupportedType:        return "AudioComponent Unsupported Type"
            
            //***** Audio errors
        case kAudio_BadFilePathError:      return "Audio Bad File Path Error"
        case kAudio_FileNotFoundError:     return "Audio File Not Found Error"
        case kAudio_FilePermissionError:   return "Audio File Permission Error"
        case kAudio_MemFullError:          return "Audio Mem Full Error"
        case kAudio_ParamError:            return "Audio Param Error"
        case kAudio_TooManyFilesOpenError: return "Audio Too Many Files Open Error"
        case kAudio_UnimplementedError:    return "Audio Unimplemented Error"
            
        default: return nil
        } // switch(self)
    } // detailedErrorMessage
    
    //**************************
    func debugLog(filePath: String = #file, line: Int = #line, funcName: String = #function) {
        guard isDebug, self != noErr else { return }
        let fileComponents = filePath.components(separatedBy: "/")
        let fileName = fileComponents.last ?? "???"
        
        var logString = "OSStatus = \(self) in \(fileName) - \(funcName), line \(line)"
        
        if let errorMessage = self.detailedErrorMessage() { logString = errorMessage + ", " + logString }
        else if let errorCode = self.asString()           { logString = errorCode    + ", " + logString }
        
        NSLog(logString)
    } // debugLog
} // extension OSStatus




// Utility Functions

//func checkError(error:OSStatus, operation: String){
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
//}



//func fourCharCodeFrom(string : String) -> FourCharCode
//{
//    assert(string.count == 4, "String length must be 4")
//    var result : FourCharCode = 0
//    for char in string.utf16 {
//        result = (result << 8) + FourCharCode(char)
//    }
//    return result
//}

//func fourCharCodeSwiftier(from string : String) -> FourCharCode
//{
//    return string.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
//}

