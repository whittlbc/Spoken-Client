//
//  Mic.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class Mic {
    
    let bus: AVAudioNodeBus = 0
    
    let bufferSize: AVAudioFrameCount = 1024
    
    var isConfigured = false
    
    private var isMicTapped = false
    
    private var audioEngine: AVAudioEngine!
    
    private var speechRecognizer = SpeechRecognizer(locale: AV.locale)!
    
    func configure() {
        // No need to do anything if already configured.
        if isConfigured {
            return
        }
        
        // Create audio engine.
        createAudioEngine()
        
        // Start audio engine.
        startAudioEngine()
            
        // Set status to configured.
        isConfigured = true
    }
    
    func startChannelPromptAnalyzer(channels: [Channel], onChannelPrompted: @escaping (Any) -> Void) {
        // TODO: Will need to ensure there isn't an active recording as well in the below clause.
        
        // Ensure class is configured and speech recognition is allowed/not-running.
        guard isConfigured && speechRecognizer.isConfigured() && !speechRecognizer.isRunning else {
            return
        }

        // Configure speech analysis to look for channel prompts.
        speechRecognizer.setAnalyzer(toType: .channelPrompt)
                
        // Pass channels to analyzer so it knows which ones to listen for.
        if let analyzer = speechRecognizer.analyzer as? ChannelPromptSpeechAnalyzer {
            analyzer.channels = channels
        }

        // Set up callback to handle when a channel has been successfully prompted.
        speechRecognizer.onKeySpeechResult = onChannelPrompted

        // Start speech recognition.
        speechRecognizer.start()
        
        // Install mic tap.
        tapMic()
    }

    // Stop speech recognition.
    func stopSpeechRecognition() {
        speechRecognizer.stop()
    }
    
    private func createAudioEngine() {
        // Create audio engine.
        audioEngine = AVAudioEngine()
        
        // Access input node to force it's creation.
        let _ = audioEngine.inputNode
    }

    // Prepare and start audio engine.
    private func startAudioEngine() {
        audioEngine.prepare()
                
        do {
            try audioEngine.start()
        } catch {
            fatalError("Audio engine failed to start with error: \(error)")
        }
    }
    
    private func tapMic() {
        // Ensure mic isn't already tapped.
        if isMicTapped {
            return
        }
        
        isMicTapped = true
        
        audioEngine.inputNode.installTap(
            onBus: bus,
            bufferSize: bufferSize,
            format: audioEngine.inputNode.outputFormat(forBus: bus)
        ) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self?.handleMicInput(buffer: buffer, when: when)
        }
    }
    
    private func untapMic() {
        // Ensure mic is currently tapped.
        guard isMicTapped else {
            return
        }
        
        isMicTapped = false

        audioEngine.inputNode.removeTap(onBus: bus)
    }
    
    private func handleMicInput(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        speechRecognizer.handleMicInput(buffer: buffer)
    }
}
