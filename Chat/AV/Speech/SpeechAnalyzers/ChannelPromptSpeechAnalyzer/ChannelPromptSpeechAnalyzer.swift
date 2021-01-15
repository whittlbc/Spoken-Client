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

    private var channelPrompts = [String: String]()
    
    override init() {
        super.init()
        populateChannelPrompts()
    }

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
        
//        // Get an ordered list of channel recipient names.
//        getChannelRecipientNames { [weak self] result in
//            guard let res = result else {
//                return
//            }
//
//            // Create map of names already seen.
//            var namesSeen = Set<String>()
//
//            for (channelId, name) in res {
//                // Get first name of recipient in channel.
//                let firstName = name.first.lowercased()
//
//                // Register name as seen if it hasn't been seen yet.
//                if namesSeen.contains(firstName) {
//                    continue
//                } else {
//                    namesSeen.insert(firstName)
//                }
//
//                // Register each lead phrase + name combination as a channel prompt.
//                for leadPhrase in ChannelPromptSpeechAnalyzer.promptLeadPhrases {
//                    if let prompt = self?.formatPrompt(leadPhrase: leadPhrase, name: firstName) {
//                        self?.channelPrompts[prompt] = channelId
//                    }
//                }
//            }
//        }
    }

    private func formatPrompt(leadPhrase: String, name: String) -> String {
        (leadPhrase + " " + name).lowercased()
    }
    
    private func getChannelRecipientNames(then handler: @escaping ([(String, Name)]?) -> Void) {
//        dataProvider.workspace.current { [weak self] workspace, error in
//            guard error == nil, let ws = workspace else {
//                handler(nil)
//                return
//            }
//
//            dataProvider.channel.list(ids: ws.channelIds) { [weak self] channels, error in
//                guard error == nil, let channelsList = channels, !channelsList.isEmpty else {
//                    handler(nil)
//                    return
//                }
//
//                var result = [(String, Name)]()
//
//                // TODO: Figure out how to iterate over this
//                for channel in channelsList {
//                    guard let recipientId = channel.memberIds.first(where: { $0 != Session.currentUserId! }) else {
//                        continue
//                    }
//
//                    dataProvider.member.get(id: recipientId) { member, error in
//                        guard error == nil, let mem = member else {
//                            return
//                        }
//
//
//                        // Get user avatar for user id.
//                        dataProvider.user.get(id: mem.userId) { user, error in
//                            guard error == nil, let name = user?.name else {
//                                return
//                            }
//
//                            result.append((channel.id, name))
//                        }
//                    }
//                }
//            }
//        }
    }
    
    // Load the current workspace.
    func getChannelRecipientNames() {
        // Get current workspace.
//        dataProvider.workspace.current { [weak self] workspace, error in
//            // Handle any errors.
//            guard error == nil, let ws = workspace else {
//                return
//            }
//
//        }
    }
    // Load the current workspace's channels.
    private func loadWorkspaceChannels() {
//        // Ensure current workspace exists.
//        guard let ws = workspace else {
//            return
//        }
//
//        // Get list of channels in current workspace.
//        dataProvider.channel.list(ids: ws.channelIds) { [weak self] channels, error in
//            // Handle any errors.
//            if let err = error {
//                self?.render(.failed(err))
//                return
//            }
//
//            // Set current channels.
//            self?.channels = channels ?? [Channel]()
//
//            // Render window as loaded.
//            self?.render(.loaded)
//        }
    }
}

