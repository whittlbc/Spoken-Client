//
//  JanusOfferMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

class JanusOfferMessage: JanusMessage {
    
    var janus = JanusMessage.Key.message
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
    
    var jsep: JanusJSEP!
}

class JanusPublisherOfferMessage: JanusOfferMessage {
        
    var body: JanusPublisherOfferMessageBody!
    
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
        requestType: JanusPublisherOfferMessageBody.RequestType,
        audio: Bool,
        video: Bool
    ) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        self.jsep = jsep
        self.body = JanusPublisherOfferMessageBody(
            requestType: requestType,
            audio: audio,
            video: video
        )
    }
}

class JanusPublisherOfferMessageBody: JanusMessage {
    
    enum RequestType: String {
        case configure
    }

    var request: String!
    
    var audio: Int!
    
    var video: Int!

    convenience init(requestType: RequestType, audio: Bool, video: Bool) {
        self.init()
        self.request = requestType.rawValue
        self.audio = audio ? 1 : 0
        self.video = video ? 1 : 0
    }
}
