//
//  JanusRecordPlayConfigureAVMessage.swift
//  Chat
//
//  Created by Ben Whittle on 3/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusRecordPlayConfigureAVMessage: Codable, ArrowParsable {

    var janus = JanusMessage.Key.message
    
    var sessionId: Int!
    
    var handleId: Int!
    
    var txId: String!
    
    var body: JanusRecordPlayConfigureAVMessageBody!
    
    enum CodingKeys: String, CodingKey {
        case janus
        case sessionId = "session_id"
        case handleId = "handle_id"
        case txId = "transaction"
        case body
    }

    convenience init(
        sessionId: Int,
        handleId: Int,
        txId: String,
        requestType: JanusRecordPlayConfigureAVMessageBody.RequestType,
        videoBitrateMax: Int,
        videoKeyframeInterval: Int
    ) {
        self.init()
        self.sessionId = sessionId
        self.handleId = handleId
        self.txId = txId
        self.body = JanusRecordPlayConfigureAVMessageBody(
            requestType: requestType,
            videoBitrateMax: videoBitrateMax,
            videoKeyframeInterval: videoKeyframeInterval
        )
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}

class JanusRecordPlayConfigureAVMessageBody: Codable, ArrowParsable {
    
    enum RequestType: String {
        case configure
    }

    var request: String!
        
    var videoBitrateMax: Int!
    
    var videoKeyframeInterval: Int!
    
    enum CodingKeys: String, CodingKey {
        case request
        case videoBitrateMax = "video-bitrate-max"
        case videoKeyframeInterval = "video-keyframe-interval"
    }
    
    convenience init(requestType: RequestType, videoBitrateMax: Int, videoKeyframeInterval: Int) {
        self.init()
        self.request = requestType.rawValue
        self.videoBitrateMax = videoBitrateMax
        self.videoKeyframeInterval = videoKeyframeInterval
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
