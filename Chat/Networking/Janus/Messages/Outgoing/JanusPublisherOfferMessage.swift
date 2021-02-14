//
//  JanusOfferMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusPublisherOfferMessage: Codable, ArrowParsable {
        
    var janus = JanusMessage.Key.message
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
    
    var jsep: JanusJSEP!

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
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

class JanusPublisherOfferMessageBody: Codable, ArrowParsable {
    
    enum RequestType: String {
        case configure
    }

    var request: String!
    
    var audio: Bool!
    
    var video: Bool!

    convenience init(requestType: RequestType, audio: Bool, video: Bool) {
        self.init()
        self.request = requestType.rawValue
        self.audio = audio
        self.video = video
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
