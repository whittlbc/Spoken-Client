//
//  SpeechRecognizer.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

class SpeechRecognizer: SFSpeechRecognizer, SpeechAnalyzerDelegate {

    var isRunning = false

    var analyzer: SpeechAnalyzerProtocol?
    
    var onKeySpeechResult: ((Any) -> Void)?
    
    var keyResultSeen = false
    
    var speechDelegate: SpeechRecognizerDelegate?

    private var request: SFSpeechAudioBufferRecognitionRequest?

    private var task: SFSpeechRecognitionTask?
    
    func isConfigured() -> Bool {
        SpeechRecognizer.isAuthed() && isAvailable
    }

    func setAnalyzer(toType type: SpeechAnalyzerType) {
        // Don't update analyzer if the current one is already of this id.
        if let currentAnalyzer = analyzer, currentAnalyzer.getType() == type {
            return
        }
        
        // Set analyzer to new instance of type.
        analyzer = type.newAnalyzer()
                
        // Take role of analyzer delegate.
        analyzer?.delegate = self
    }

    func start() {
        // Don't start if already running.
        if isRunning {
            return
        }
        
        keyResultSeen = false
        
        // Create speech recognition request.
        createRequest()
        
        // Create speech recognition task.
        createTask()
        
        // Register self as running.
        isRunning = true
    }
    
    func stop() {
        // Ensure speech recognition is running.
        guard isRunning else {
            return
        }
                
        // Cancel speech recognition request.
        cancelRequest()
        
        // Cancel speech recognition task.
        cancelTask()
                
        // Register self as stopped.
        isRunning = false
    }
    
    func handleMicInput(buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }
    
    func handleKeySpeechResult(result: Any, shouldStop: Bool) {
        keyResultSeen = true
        
        // Bubble up key result.
        onKeySpeechResult?(result)
        
        // Stop speech recognition is told to.
        if shouldStop {
            stop()
        }
    }
    
    private func createRequest() {
        request = SFSpeechAudioBufferRecognitionRequest()

        guard let req = request else {
            fatalError("Buffer recognition request failed to be created.")
        }

        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        
        // Add contextual strings from analyzer if they exist.
        if let contextualStrings = analyzer?.getContextualStrings() {
            req.contextualStrings = contextualStrings
        }
    }

    private func cancelRequest() {
        request?.endAudio()
    }

    private func createTask() {
        task = recognitionTask(with: request!) { [weak self] result, error in
            if let err = error {
                self?.handleRecognitionError(err)
            }
            
            if let res = result {
                self?.analyze(result: res)
            }
            
            if result == nil || result!.isFinal {
                self?.onStopped()
            }
        }
    }

    private func cancelTask() {
        task?.finish()
    }
    
    private func analyze(result: SFSpeechRecognitionResult) {
        analyzer?.analyzeResult(result: result)
    }
    
    private func onStopped() {
        speechDelegate?.onSpeechRecognitionStopped(keyResultSeen: keyResultSeen)
    }
    
    private func handleRecognitionError(_ error: Error) {
        if isRunning {
            logger.error("Recognition error occurred while running: \(error)")
        }
    }
}

