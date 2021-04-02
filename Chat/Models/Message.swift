//
//  Message.swift
//  Chat
//
//  Created by Ben Whittle on 1/3/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

enum MessageType: String {
    case audio
    case video
}

enum MessageStatus: String {
    case recording
    case recorded
    case uploaded
    case sending
    case sent
    case cancelled
}

struct Message: Model {
    
    static var modelName = "message"

    var id = ""
    var channelId = ""
    var senderId = ""
    var messageType = ""
    var status = ""
    var failed = false
    var token = ""
    var url = ""
    
    var sender: Member?
        
    var isAudio: Bool { getMessageType() == .audio }

    var isVideo: Bool { getMessageType() == .video }
    
    var isRecording: Bool { getStatus() == .recording }

    var isRecorded: Bool { getStatus() == .recorded }

    var isUploaded: Bool { getStatus() == .uploaded }

    var isSending: Bool { getStatus() == .sending }

    var isSent: Bool { getStatus() == .sent }
    
    var isCancelled: Bool { getStatus() == .cancelled }

    func getMessageType() -> MessageType? {
        MessageType(rawValue: messageType)
    }
    
    func getStatus() -> MessageStatus? {
        MessageStatus(rawValue: status)
    }
    
    func forCache() -> Message {
        self
    }
}
