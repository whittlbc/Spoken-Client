//
//  JanusRecordPlayPublisherOfferMessage.swift
//  Chat
//
//  Created by Ben Whittle on 3/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusRecordPlayPublisherOfferMessage: Codable, ArrowParsable {
        
    var janus = JanusMessage.Key.message
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
    
    var jsep: JanusJSEP!

    var body: JanusRecordPlayPublisherOfferMessageBody!
    
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
        requestType: JanusRecordPlayPublisherOfferMessageBody.RequestType,
        recordingId: Int
    ) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        self.jsep = jsep
        self.body = JanusRecordPlayPublisherOfferMessageBody(
            requestType: requestType,
            id: recordingId
        )
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

class JanusRecordPlayPublisherOfferMessageBody: Codable, ArrowParsable {
    
    enum RequestType: String {
        case record
    }

    var request: String!
    
    var id: Int!
    
    var name: String!
    
    var filename: String!
    
    var audiocodec: String!
    
    var videocodec: String!
        
    convenience init(requestType: RequestType, id: Int) {
        self.init()
        self.request = requestType.rawValue
        self.id = id
        self.name = String(id)
        self.filename = String(id)
        self.audiocodec = "opus"
        self.videocodec = "vp8"
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
