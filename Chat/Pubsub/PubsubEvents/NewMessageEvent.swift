//
//  NewMessageEvent.swift
//  Chat
//
//  Created by Ben Whittle on 4/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class NewMessageEvent: Codable, ArrowParsable {
    
    static func fromJSON(_ json: JSON) -> Self {
        let event = Self()
        event.deserialize(json)
        return event
    }

    var message = Message()

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        message <-- json["message"]
    }
}
