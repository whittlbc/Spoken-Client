//
//  JanusTrickleCandidateMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC
import Arrow

class JanusTrickleCandidateMessage: Codable, ArrowParsable {
    
    var janus = JanusMessage.Key.trickle
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!

    var candidate: JanusTrickleCandidateMessageCandidate?
    
    enum CodingKeys: String, CodingKey {
        case janus
        case sessionId = "session_id"
        case handleId = "handle_id"
        case txId = "transaction"
        case candidate
    }

    convenience init(sessionId: Int, handleId: Int, txId: String, iceCandidate: RTCIceCandidate) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        
        guard let sdpMid = iceCandidate.sdpMid else {
            return
        }
        
        self.candidate = JanusTrickleCandidateMessageCandidate(
            sdp: iceCandidate.sdp,
            sdpMid: sdpMid,
            sdpMLineIndex: Int(iceCandidate.sdpMLineIndex)
        )
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

class JanusTrickleCandidateMessageCandidate: Codable, ArrowParsable {
    
    var candidate: String!
    
    var sdpMid: String!
    
    var sdpMLineIndex: Int!

    convenience init(sdp: String, sdpMid: String, sdpMLineIndex: Int) {
        self.init()
        self.candidate = sdp
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
