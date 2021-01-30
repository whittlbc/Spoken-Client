//
//  Message+Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 1/3/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

extension Message: ArrowParsable {
    
    public mutating func deserialize(_ json: JSON) {
        id <-- json["id"]
        channelId <-- json["channel_id"]
        senderId <-- json["sender_id"]
        messageType <-- json["message_type"]
        files <-- json["files"]
    }
}
