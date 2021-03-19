//
//  Workspace+Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

extension Workspace: ArrowParsable {
    
    public mutating func deserialize(_ json: JSON) {
        id <-- json["id"]
        name <-- json["name"]
        slug <-- json["slug"]
        memberIds <-- json["member_ids"]
        channelIds <-- json["channel_ids"]
    }
}
