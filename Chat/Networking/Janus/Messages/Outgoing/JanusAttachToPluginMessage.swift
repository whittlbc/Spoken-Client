//
//  JanusAttachToPluginMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusAttachToPluginMessage: Codable, ArrowParsable {
    
    var janus = JanusMessage.Key.attach
    
    var plugin: String!
    
    var sessionId: Int!
    
    var txId: String!
    
    enum CodingKeys: String, CodingKey {
        case janus
        case plugin
        case sessionId = "session_id"
        case txId = "transaction"
    }

    convenience init(plugin: String, sessionId: Int, txId: String) {
        self.init()
        self.plugin = plugin
        self.sessionId = sessionId
        self.txId = txId
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
