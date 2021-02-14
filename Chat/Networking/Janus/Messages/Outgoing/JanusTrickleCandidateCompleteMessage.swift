//
//  JanusTrickleCandidateCompleteMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/10/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC
import Arrow

class JanusTrickleCandidateCompleteMessage: Codable, ArrowParsable {

    var janus = JanusMessage.Key.trickle
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!

    var candidate: JanusTrickleCandidateCompleteMessageCandidate!
    
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
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

class JanusTrickleCandidateCompleteMessageCandidate: Codable, ArrowParsable {
    
    var completed: Int = 1
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
