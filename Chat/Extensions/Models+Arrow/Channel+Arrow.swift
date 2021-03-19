//
//  Channel+Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 1/3/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

extension Channel: ArrowParsable {
    
    public mutating func deserialize(_ json: JSON) {
        id <-- json["id"]
        name <-- json["name"]
        slug <-- json["slug"]
        isUserCreated <-- json["isUserCreated"]
        workspaceId <-- json["workspaceId"]
        memberIds <-- json["member_ids"]
    }
}
