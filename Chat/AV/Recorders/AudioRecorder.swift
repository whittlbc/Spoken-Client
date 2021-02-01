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
    
    var recordingSize: Int { audioRecording?.size ?? 0 }
    
    var recordingPath: URL? { audioRecording?.filePath }
        
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
        // Only stop if an active audio recording exists.
        guard audioRecording != nil && isRecording else {
            return
        }
        
        // Register active recording as stopped.
        isRecording = false
        
        // Tell the recording to finish.
        audioRecording!.finish()
    }
    
    func clear() {
        audioRecording = nil
    }
    
    func handleMicInput(data: Data) {
        if isRecording {
            audioRecording?.append(data)
        }
    }
    
    private func createAudioRecording() {
        audioRecording = AudioRecording()
    }
}
