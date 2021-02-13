//
//  JanusMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import WebRTC

typealias JanusJSEP = [AnyHashable: Any]

class JanusMessage: Codable, ArrowParsable {
    
    enum Key {
        static let janus = "janus"
        static let videoRoomPlugin = "janus.plugin.videoroom"
        static let create = "create"
        static let attach = "attach"
        static let detach = "detach"
        static let keepAlive = "keepalive"
        static let transaction = "transaction"
        static let message = "message"
        static let trickle = "trickle"
        static let error = "error"
        static let code = "code"
        static let reason = "reason"
        static let data = "data"
        static let id = "id"
        static let videoRoom = "videoroom"
        static let publishers = "publishers"
        static let leaving = "leaving"
        static let display = "display"
        static let pluginData = "plugindata"
        static let sender = "sender"
        static let jsep = "jsep"
        static let type = "type"
        static let sdp = "sdp"
    }
    
    enum IncomingMessageType: String {
        case success
        case error
        case event
        case detached
        case ack
    }
    
    static func fromJSON(_ json: JSON) -> Self {
        let message = Self()
        message.deserialize(json)
        return message
    }
    
    static func newJSEP(fromSDP sdp: RTCSessionDescription) -> JanusJSEP {
        [
            Key.type: RTCSessionDescription.string(for: sdp.type),
            Key.sdp: sdp.sdp
        ]
    }
    
    required init() {}
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
