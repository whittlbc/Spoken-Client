//
//  SpeechAnalyzerProtocol.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

protocol SpeechAnalyzerProtocol: class {
    
    var delegate: SpeechAnalyzerDelegate? { get set }
    
    func getType() -> SpeechAnalyzerType
    
    func getContextualStrings() -> [String]
    
    func analyzeResult(result: SFSpeechRecognitionResult)
}
