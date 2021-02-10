//
//  JanusAttachToPluginMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

class JanusAttachToPluginMessage: JanusMessage {
    
    var janus = JanusMessage.Key.attach
    
    var plugin = JanusMessage.Key.videoRoomPlugin
    
    var sessionId: Int!
    
    var txId: String!
    
    enum CodingKeys: String, CodingKey {
        case janus
        case plugin
        case sessionId = "session_id"
        case txId = "transaction"
    }

    convenience init(sessionId: Int, txId: String) {
        self.init()
        self.sessionId = sessionId
        self.txId = txId
    }
}
