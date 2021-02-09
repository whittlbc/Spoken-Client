//
//  JanusKeepAlive.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

class JanusKeepAliveMessage: JanusMessage {
    
    var janus = JanusMessage.Key.keepalive
    
    var sessionId: Int!
    
    var txId: String!
    
    enum CodingKeys: String, CodingKey {
        case janus
        case sessionId = "session_id"
        case txId = "transaction"
    }
    
    convenience init(sessionId: Int) {
        self.init()
        self.sessionId = sessionId
        self.txId = String.random(length: 12)
    }
}
