//
//  SpeechAnalyzer.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

class SpeechAnalyzer: SpeechAnalyzerProtocol {
    
    weak var delegate: SpeechAnalyzerDelegate?

    func getType() -> SpeechAnalyzerType { .unknown }
    
    func getContextualStrings() -> [String] { [] }
    
    func analyzeResult(result: SFSpeechRecognitionResult) {}
    
    func parseWords(forTranscription transcription: SFTranscription) -> [String] {
        transcription.formattedString.trimmingCharacters(in: [" "]).split(separator: " ").map { String($0) }
    }
}
