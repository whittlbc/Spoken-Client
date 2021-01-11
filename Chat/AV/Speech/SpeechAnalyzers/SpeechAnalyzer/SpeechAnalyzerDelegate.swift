//
//  SpeechAnalyzerDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

protocol SpeechAnalyzerDelegate: class {
    
    func handleKeySpeechResult(result: Any, shouldStop: Bool)
}
