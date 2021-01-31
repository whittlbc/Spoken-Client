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

    func forCache() -> Message {
        var message = self
        message.files = []
        return message
    }
}
