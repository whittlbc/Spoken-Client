//
//  SpeechRecognizerDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 1/8/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

protocol SpeechRecognizerDelegate: class {
    
    func onSpeechRecognitionStopped(keyResultSeen: Bool)
}
