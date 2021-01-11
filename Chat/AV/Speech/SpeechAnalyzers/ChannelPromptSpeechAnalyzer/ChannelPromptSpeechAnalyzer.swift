//
//  ChannelPromptSpeechAnalyzer.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

class ChannelPromptSpeechAnalyzer: SpeechAnalyzer {
    
    static let promptLeadPhrases = ["hey", "yo"]

    var channels: [Channel]! {
        didSet { self.populateChannelPrompts() }
    }

    private var channelPrompts = [String: String]()

    override func getType() -> SpeechAnalyzerType { .channelPrompt }
    
    override func getContextualStrings() -> [String] { [String](channelPrompts.keys) }
    
    override func analyzeResult(result: SFSpeechRecognitionResult) {
        // Get list of words from the best transcription.
        let words = parseWords(forTranscription: result.bestTranscription)
        
        // Ensure there are at least 2 words in the transcription (leading phrase + name).
        guard words.count > 1 else {
            return
        }
        
        // Use the first 2 words of the transcription to create a command prompt.
        let commandPrompt = formatPrompt(leadPhrase: String(words[0]), name: String(words[1]))

        // Check to see if this is a registered channel prompt.
        guard let channelId = channelPrompts[commandPrompt] else {
            return
        }
        
        // Handle channel prompt match and stop the speech recognizer.
        delegate?.handleKeySpeechResult(result: channelId, shouldStop: true)
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
            for leadPhrase in ChannelPromptSpeechAnalyzer.promptLeadPhrases {
                channelPrompts[formatPrompt(leadPhrase: leadPhrase, name: name)] = channel.id
            }
        }
    }

    private func formatPrompt(leadPhrase: String, name: String) -> String {
        (leadPhrase + " " + name).lowercased()
    }
}

