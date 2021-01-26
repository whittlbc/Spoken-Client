//
//  AudioSession.swift
//  Chat
//
//  Created by Ben Whittle on 1/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

public enum AV {
    
    static let locale = Locale(identifier: "en-US")
    
    static let mic = MicTap()
    
    static let avRecorder = AVRecorder()
    
    static func seekPermissions() {
        // Ask permission to access the mic.
        seekMicPermission()
        
        // Ask permission to use speech recognition on mic audio input (if user has feature enabled).
        if UserSettings.SpeechRecognition.isEnabled {
            seekSpeechRecognitionPermission()
        }
        
        // Ask permission to use the camera if the user wants to use video.
        if UserSettings.Video.useCamera {
            seekCameraPermission()
        }
    }
    
    static func seekMicPermission() {
        // Switch over the current auth status for mic access.
        switch AVCaptureDevice.authorizationStatus(for: .audio) {

        // If already authorized, go ahead and configure the mic.
        case .authorized:
            mic.configure()
        
        // If user hasn't been asked yet, ask for permission.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                // Configure mic when access is granted.
                if granted {
                    mic.configure()
                }
            }
            
        // Log error if device restricts mic access.
        case .restricted:
            logger.error("Seeking mic permission failed -- device restricts mic access.")
        
        // Log error if user denies mic access.
        case .denied:
            logger.error("Seeking mic permission failed -- user denied access.")
        
        // Handle unknown cases that may arise in future versions.
        default:
            break
        }
    }

    static func seekSpeechRecognitionPermission() {
        // Switch over the current auth status for speech recognition access.
        switch SFSpeechRecognizer.authorizationStatus() {

        // If user hasn't been asked yet, ask for permission.
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { _ in
                return
            }
            
        // Log error if device restricts speech recognition.
        case .restricted:
            logger.error("Seeking speech recognition permission failed -- device restricts speech recognition.")
        
        // Log error if user denies speech recognition permission.
        case .denied:
            logger.error("Seeking speech recognition permission failed -- user denied permission.")
        
        // Handle unknown cases that may arise in future versions.
        default:
            break
        }
    }
    
    static func seekCameraPermission() {
        // Switch over the current auth status for camera access.
        switch AVCaptureDevice.authorizationStatus(for: .video) {

        // If already authorized, go ahead and configure the inputs requiring camera access.
        case .authorized:
            return
        
        // If user hasn't been asked yet, ask for permission.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                // Configure inputs requiring camera access when granted.
                if granted {
                    return
                }
            }
            
        // Log error if device restricts camera access.
        case .restricted:
            logger.error("Seeking camera permission failed -- device restricts camera access.")
        
        // Log error if user denies camera access.
        case .denied:
            logger.error("Seeking camera permission failed -- user denied access.")
        
        // Handle unknown cases that may arise in future versions.
        default:
            break
        }
    }
}
