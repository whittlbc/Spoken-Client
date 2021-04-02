//
//  StreamConfig.swift
//  Chat
//
//  Created by Ben Whittle on 4/1/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AgoraRtcKit

enum StreamConfig {
    
    enum DeviceType {
        case audioRecording(String?)
        case audioPlayout(String?)
        case videoCapture(String?)
        
        var id: String? {
            switch self {
            
            // Audio recording device.
            case .audioRecording(let id):
                return id
                
            // Audio playout device.
            case .audioPlayout(let id):
                return id
            
            // Video capture device.
            case .videoCapture(let id):
                return id
            }
        }
    }

    static var audioRecordingDevice = DeviceType.audioRecording(nil)
    
    static var audioPlayoutDevice = DeviceType.audioPlayout(nil)
    
    static var videoCaptureDevice = DeviceType.videoCapture(nil)
    
    static let videoEncoderConfig = AgoraVideoEncoderConfiguration(
        size: AgoraVideoDimension960x720,
        frameRate: .fps30,
        bitrate: AgoraVideoBitrateStandard,
        orientationMode: .adaptative
    )
    
    static var encryptionType = "aes-256-xts"
    
    static var recordingUserUid: UInt = 1
}
