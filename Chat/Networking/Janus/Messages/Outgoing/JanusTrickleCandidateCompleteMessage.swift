//
//  JanusTrickleCandidateCompleteMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/10/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

class JanusTrickleCandidateCompleteMessage: JanusMessage {
    
    var janus = JanusMessage.Key.trickle
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
        
    var candidate: JanusTrickleCandidateCompleteMessageCandidate
    
    enum CodingKeys: String, CodingKey {
        case janus
        case sessionId = "session_id"
        case handleId = "handle_id"
        case txId = "transaction"
        case candidate
    }

    convenience init(sessionId: Int, handleId: Int, txId: String) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        self.candidate = JanusTrickleCandidateCompleteMessageCandidate()
    }
}

class JanusTrickleCandidateCompleteMessageCandidate: JanusMessage {
    var completed: Int = 1
}
