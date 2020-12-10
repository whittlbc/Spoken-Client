//
//  Name+Arrow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow
import Networking

extension Name: ArrowParsable {
    
    public mutating func deserialize(_ json: JSON) {
        first <-- json["first"]
        last <-- json["last"]
    }
}

extension Name: NetworkingJSONDecodable {}
