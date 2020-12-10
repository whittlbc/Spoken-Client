//
//  Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

// Extend objects that are ArrowParsable and NetworkingJSONDecodable
// to make it easy for all models to be JSON-decodable.
extension ArrowParsable where Self: NetworkingJSONDecodable {

    public static func decode(_ json: Any) throws -> Self {
        var t: Self = Self()
        
        if let arrowJSON = JSON(json) {
            t.deserialize(arrowJSON)
        }
        
        return t
    }
}