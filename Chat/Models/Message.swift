//
//  Message.swift
//  Chat
//
//  Created by Ben Whittle on 1/3/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

enum MessageType: String {
    case audio = "audio"
    case video = "video"
}

struct Message: Model {
    
    static var modelName = "message"

    var id = ""
    var channelId = ""
    var senderId = ""
    var messageType = ""
    var fileIds = [String]()
    
    var files = [File]()
    
    var canConsume: Bool { files.count > 0 && !files[0].downloadURL.isEmpty }
    
    var isAudio: Bool { getMessageType() == .audio }

    var isVideo: Bool { getMessageType() == .video }

    func getMessageType() -> MessageType? {
        MessageType(rawValue: messageType)
    }
    
    func forCache() -> Message {
        var message = self
        message.files = []
        return message
    }
}
