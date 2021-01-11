//
//  SpeechAnalyzerId.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

public enum SpeechAnalyzerType: String {
    case channelPrompt
    case unknown
    
    // Create new speech analyzer instance for self type.
    func newAnalyzer() -> SpeechAnalyzerProtocol? {
        switch self {
        
        // Create new channel prompt speech analyzer.
        case .channelPrompt:
            return ChannelPromptSpeechAnalyzer()
            
        default:
            return nil
        }
    }
}
