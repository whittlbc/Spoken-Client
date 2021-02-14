//
//  JanusLeaveMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusLeaveMessage: Codable, ArrowParsable {
    
    var janus = JanusMessage.Key.detach
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!

    enum CodingKeys: String, CodingKey {
        case janus
        case sessionId = "session_id"
        case handleId = "handle_id"
        case txId = "transaction"
    }

    convenience init(sessionId: Int, handleId: Int, txId: String) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

