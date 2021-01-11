//
//  AudioRecorder.swift
//  Chat
//
//  Created by Ben Whittle on 1/8/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class AudioRecorder {

    var audioRecording: AudioRecording?
    
    var isRecording = false
        
    func start() {
        // Only start if no active audio recording exists.
        guard audioRecording == nil && !isRecording else {
            return
        }

        // Create new audio recording.
        createAudioRecording()
        
        // Register active recording as started.
        isRecording = true
    }
    
    func stop() {
        // Only start if no active audio recording exists.
        guard audioRecording != nil && isRecording else {
            return
        }
        
        // Register active recording as stopped.
        isRecording = false
    }
    
    func clear() {
        audioRecording = nil
    }
    
    func handleMicInput(buffer: AVAudioPCMBuffer) {
        if isRecording {
            audioRecording?.append(buffer)
        }
    }
    
    private func createAudioRecording() {
        audioRecording = AudioRecording()
    }
}
