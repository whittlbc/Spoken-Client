//
//  Mic.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class MicTap: SpeechRecognizerDelegate {
    
    let bus: AVAudioNodeBus = 0
    
    let bufferSize: AVAudioFrameCount = 1024
    
    var isConfigured = false
    
    private var isMicTapped = false
    
    private var audioEngine: AVAudioEngine!
    
    private var audioRecorder = AudioRecorder()
    
    private var speechRecognizer = SpeechRecognizer(locale: AV.locale)!
    
    typealias Pipe = (AVAudioPCMBuffer) -> Void
    
    private var pipes = [String:Pipe]()
    
    func configure() {
        // No need to do anything if already configured.
        if isConfigured {
            return
        }
        
        // Set self as delegate to speech recognizer.
        speechRecognizer.speechDelegate = self
        
        // Create audio engine.
        createAudioEngine()
        
        // Start audio engine.
        startAudioEngine()
            
        // Set status to configured.
        isConfigured = true
    }
    
    func addPipe(forKey key: String, pipe: @escaping Pipe) {
        pipes[key] = pipe
    }
    
    func removePipe(forKey key: String) {
        pipes.removeValue(forKey: key)
    }
    
    func startChannelPromptAnalyzer(onChannelPrompted: @escaping (Any) -> Void) {
        // Ensure class is configured, speech recognition is allowed/not-running, and no active recording exists.
        guard isConfigured &&
            speechRecognizer.isConfigured() &&
            !speechRecognizer.isRunning &&
            audioRecorder.audioRecording == nil &&
            !audioRecorder.isRecording else {
            return
        }

        // Configure speech analysis to look for channel prompts.
        speechRecognizer.setAnalyzer(toType: .channelPrompt)
                
        // Set up callback to handle when a channel has been successfully prompted.
        speechRecognizer.onKeySpeechResult = onChannelPrompted

        // Start speech recognition.
        startSpeechRecognition()
        
        // Start recording.
        startRecording()
    }
    
    // Start speech recognition.
    func startSpeechRecognition() {
        speechRecognizer.start()
    }
    
    // Stop speech recognition.
    func stopSpeechRecognition() {
        speechRecognizer.stop()
    }
    
    func onSpeechRecognitionStopped(keyResultSeen: Bool) {
        // Stop and clear recording if no key result was seen.
        if !keyResultSeen {
            stopRecording()
            clearRecording()
        }
    }
    
    func startRecording() {
        // Create new audio recording to receive mic input.
        audioRecorder.start()
        
        // Install mic tap.
        tapMic()
    }
    
    func stopRecording() {
        // Stop active audio recording.
        audioRecorder.stop()
                
        // Untap the mic.
        untapMic()
    }

    // Wipe active audio recording.
    func clearRecording() {
        audioRecorder.clear()
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
        // Pipe mic input to speech recognizer.
        speechRecognizer.handleMicInput(buffer: buffer)
        
        // Pipe mic input to audio recorder.
        audioRecorder.handleMicInput(buffer: buffer)
        
        // Pipe mic input to any custom pipes.
        for pipe in pipes.values {
            pipe(buffer)
        }
    }
}
