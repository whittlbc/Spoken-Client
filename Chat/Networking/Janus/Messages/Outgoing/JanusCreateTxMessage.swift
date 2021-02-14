//
//  JanusCreateTxMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusCreateTxMessage: Codable, ArrowParsable {
    
    var janus = JanusMessage.Key.create
    
    var txId: String!
    
    enum CodingKeys: String, CodingKey {
        case janus
        case txId = "transaction"
    }

    convenience init(txId: String) {
        self.init()
        self.txId = txId
    }

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func deserialize(_ json: JSON) {}
}
