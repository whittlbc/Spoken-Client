//
//  ChannelPromptSpeechRecognizer.swift
//  Chat
//
//  Created by Ben Whittle on 1/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

class ChannelSpeechRecognizer: SFSpeechRecognizer {
    
    static let promptLeadPhrases = ["hey", "yo"]
    
    weak var channelDelegate: ChannelSpeechRecognizerDelegate? {
        get { return delegate as? ChannelSpeechRecognizerDelegate }
        set { delegate = newValue }
    }
    
    var isListening = false
    
    var channels: [Channel]! {
        didSet { self.populateChannelPrompts() }
    }
    
    private var channelPrompts = [String: String]()
        
    private let audioEngine = AVAudioEngine()

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private var transcriber: SFSpeechRecognitionTask?
    
    private var recordingFormat: AVAudioFormat {
        audioEngine.inputNode.outputFormat(forBus: AudioInput.bus)
    }
    
    func startListening() {
        // Reset all audio resources to base state.
        stopListening()
        
        // Create speech recognition request.
        createRecognitionRequest()
        
        // Create speech recognition task for request.
        createTranscriber()
        
        // Pipe audio input to recognition request.
        tapAudioInput()
        
        // Start audio engine.
        startAudioEngine()
        
        // Register class as listening.
        isListening = true
    }
    
    func stopListening() {
        isListening = false
        stopAudioEngine()
        cancelRecognitionRequest()
        untapAudioInput()
        cancelTranscriber()
    }
    
    private func populateChannelPrompts() {
        // Empty out channel prompts map.
        channelPrompts.removeAll()
        
        // Create map of names already seen.
        var namesSeen = Set<String>()
        
        // Add prompts for each channel.
        for channel in channels {
            // Get first name of recipient in channel.
            let name = channel.recipient.user.name.first
            let lcName = name.lowercased()
            
            // Register name as seen if it hasn't been seen yet.
            if namesSeen.contains(lcName) {
                continue
            } else {
                namesSeen.insert(lcName)
            }
                        
            // Register each lead phrase + name combination as a channel prompt.
            for leadPhrase in ChannelSpeechRecognizer.promptLeadPhrases {
                channelPrompts[formatPrompt(leadPhrase: leadPhrase, name: name)] = channel.id
            }
        }
    }
    
    private func formatPrompt(leadPhrase: String, name: String) -> String {
        (leadPhrase + " " + name).lowercased()
    }
    
    private func onTranscription(_ transcription: SFTranscription) {
        // Split the trimmed transcription string into words.
        let words = transcription.formattedString.trimmingCharacters(in: [" "]).split(separator: " ")
        
        // Ensure there are at least 2 words in the transcription (one for the leading phrase, one for the name).
        guard words.count > 1 else {
            return
        }
        
        // Use the first 2 words of the transcription to create a command prompt.
        let commandPrompt = formatPrompt(leadPhrase: String(words[0]), name: String(words[1]))
        
        // Check to see if this is a registered channel prompt.
        guard let channelId = channelPrompts[commandPrompt] else {
            return
        }
                
        // TODO: Stop transcribing and create a new audio buffer to continue a recording from the start of this command prompt.
        stopListening()
        
        // Let delegate know that a channel has been prompted.
        channelDelegate?.onChannelSpeechRecognized(channelId: channelId)
    }
    
    private func onTranscriptionError(_ error: Error) {
        if error._domain == "EARErrorDomain" {
            logger.warning("Restarting recognition due to length of silence...")
            self.startListening()
        }
    }
    
    private func startAudioEngine() {
        // Prep audio engine for start.
        audioEngine.prepare()
                
        do {
            try audioEngine.start()
        } catch {
            fatalError("Audio engine failed to start with error: \(error)")
        }
    }
    
    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    private func tapAudioInput() {
        audioEngine.inputNode.installTap(
            onBus: AudioInput.bus,
            bufferSize: AudioInput.bufferSize,
            format: recordingFormat
        ) { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self?.recognitionRequest?.append(buffer)
        }
    }
    
    private func untapAudioInput() {
        audioEngine.inputNode.removeTap(onBus: AudioInput.bus)
    }
    
    private func createTranscriber() {
        transcriber = recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            if let err = error {
                self?.onTranscriptionError(err)
                return
            }
            
            if let result = result, self?.isListening == true {
                self?.onTranscription(result.bestTranscription)
            }
        }
    }
    
    private func cancelTranscriber() {
        transcriber?.finish()
    }
    
    private func createRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = recognitionRequest else {
            fatalError("Buffer recognition request failed to be created.")
        }
                
        request.shouldReportPartialResults = true
        request.contextualStrings = [String](channelPrompts.keys)
        request.requiresOnDeviceRecognition = true
    }
    
    private func cancelRecognitionRequest() {
        recognitionRequest?.endAudio()
    }
}
