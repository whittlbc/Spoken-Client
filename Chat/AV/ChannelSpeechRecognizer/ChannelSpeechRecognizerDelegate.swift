//
//  ChannelSpeechRecognizerDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 1/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Speech

protocol ChannelSpeechRecognizerDelegate: SFSpeechRecognizerDelegate {
    
    func onChannelSpeechRecognized(channelId: String)
}
