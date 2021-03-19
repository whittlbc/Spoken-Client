//
//  JanusVideoRoomSubscriberAnswerMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusVideoRoomSubscriberAnswerMessage: Codable, ArrowParsable {
        
    var janus = JanusMessage.Key.message
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
    
    var jsep: JanusJSEP!

    var body: JanusVideoRoomSubscriberAnswerMessageBody!
    
    enum CodingKeys: String, CodingKey {
        case janus
        case sessionId = "session_id"
        case handleId = "handle_id"
        case txId = "transaction"
        case jsep
        case body
    }

    convenience init(
        sessionId: Int,
        handleId: Int,
        txId: String,
        jsep: JanusJSEP,
        requestType: JanusVideoRoomSubscriberAnswerMessageBody.RequestType,
        room: Int
    ) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        self.jsep = jsep
        self.body = JanusVideoRoomSubscriberAnswerMessageBody(
            requestType: requestType,
            room: room
        )
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

class JanusVideoRoomSubscriberAnswerMessageBody: Codable, ArrowParsable {
    
    enum RequestType: String {
        case start
    }

    var request: String!
    
    var room: Int!
    
    convenience init(requestType: RequestType, room: Int) {
        self.init()
        self.request = requestType.rawValue
        self.room = room
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
