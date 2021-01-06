//
//  AudioSession.swift
//  Chat
//
//  Created by Ben Whittle on 1/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

public enum AudioInput {
    
    static let bus: AVAudioNodeBus = 0
    
    static let bufferSize: AVAudioFrameCount = 1024
    
    static let locale = Locale(identifier: "en-US")
    
    // Check if speech recognition permissions have been granted for this app.
    static func speechRecognitionIsAuthorized() -> Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    static func requestSpeechRecognitionPermission(onAccepted: @escaping () -> Void) {
        // Accept early if already authorized.
        if AudioInput.speechRecognitionIsAuthorized() {
            onAccepted()
            return
        }
        
        // Prompt user to grant speech recognition permissions.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            let request = "Speech recognition permission request"
            
            switch authStatus {
            
            // Accepted
            case .authorized:
                onAccepted()
                
            // Denied
            case .denied:
                logger.warning("\(request): Denied by user.")
                
            // Device doesn't allow speech recognition
            case .restricted:
                logger.warning("\(request): Device restricts this functionality.")
                
            // Still undecided
            case .notDetermined:
                logger.warning("\(request): Still undetermined...")
                
            // Unknown
            default:
                logger.warning("\(request): Unknown auth status.")
            }
        }
    }
}
