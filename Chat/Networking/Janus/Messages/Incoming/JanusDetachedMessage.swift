//
//  JanusDetachedMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusDetachedMessage: Codable, ArrowParsable {
    
    static func fromJSON(_ json: JSON) -> Self {
        let message = Self()
        message.deserialize(json)
        return message
    }
    
    var janus = ""
    
    var sender: Int = 0
    
    var hasSender: Bool { sender != 0 }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        janus <-- json[JanusMessage.Key.janus]
        sender <-- json[JanusMessage.Key.sender]
    }
}

