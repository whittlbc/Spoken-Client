//
//  Member+Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

extension Member: ArrowParsable {
    
    public mutating func deserialize(_ json: JSON) {
        id <-- json["id"]
        userId <-- json["user_id"]
    }
}
