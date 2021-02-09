//
//  JanusDetachedMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusDetachedMessage: JanusMessage {
    
    var janus = ""
    
    var sender: Int = 0
    
    var hasSender: Bool { sender != 0 }
    
    override func deserialize(_ json: JSON) {
        janus <-- json[JanusMessage.Key.janus]
        sender <-- json[JanusMessage.Key.sender]
    }
}

