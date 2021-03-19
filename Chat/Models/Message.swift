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
    case pending
    case recording
    case recorded
}

struct Message: Model {
    
    static var modelName = "message"

    var id = ""
    var channelId = ""
    var senderId = ""
    var messageType = ""
    var status = ""
    var failed = false
    var streamServerIP = ""
    var iceServerURLs = [WebRTCIceServer]()
    
    var sender: Member?
        
    var isAudio: Bool { getMessageType() == .audio }

    var isVideo: Bool { getMessageType() == .video }
    
    var isPending: Bool { getStatus() == .pending }

    var isRecording: Bool { getStatus() == .recording }

    var isRecorded: Bool { getStatus() == .recorded }

    func getMessageType() -> MessageType? {
        MessageType(rawValue: messageType)
    }
    
    func getStatus() -> MessageStatus? {
        MessageStatus(rawValue: status)
    }
    
    func getIceServers() -> [RTCIceServer] {
        iceServerURLs.map({ $0.toIceServer() })
    }
    
    func forCache() -> Message {
        self
    }
}
