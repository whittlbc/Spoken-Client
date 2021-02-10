//
//  JanusJoinRoomMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

class JanusJoinRoomMessage: JanusMessage {
    
    var janus = JanusMessage.Key.message
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
    
    var body: JanusJoinRoomMessageBody!
        
    enum CodingKeys: String, CodingKey {
        case janus
        case plugin
        case sessionId = "session_id"
        case handleId = "handle_id"
        case txId = "transaction"
        case body
    }

    convenience init(
        sessionId: Int,
        handleId: Int,
        txId: String,
        requestType: JanusJoinRoomMessageBody.RequestType,
        room: Int,
        ptype: JanusJoinRoomMessageBody.PType,
        feed: Int? = nil
    ) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        self.body = JanusJoinRoomMessageBody(
            requestType: requestType,
            room: room,
            ptype: ptype,
            feed: feed
        )
    }
}

class JanusJoinRoomMessageBody: JanusMessage {
    
    enum RequestType: String {
        case join
    }
    
    enum PType: String {
        case publisher
        case listener
    }

    var request: String!
    
    var room: Int!
    
    var ptype: String!
    
    var feed: Int?

    convenience init(requestType: RequestType, room: Int, ptype: PType, feed: Int? = nil) {
        self.init()
        self.request = requestType.rawValue
        self.room = room
        self.ptype = ptype.rawValue
        self.feed = feed
    }
}
