//
//  JanusTxResponseMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusTxResponseMessage: Codable, ArrowParsable {
    
    static func fromJSON(_ json: JSON) -> Self {
        let message = Self()
        message.deserialize(json)
        return message
    }
    
    var janus = ""
    
    var txId = ""
    
    var data = JanusTxResponseMessageData()
    
    var error = JanusTxResponseMessageError()
    
    var dataId: Int { data.id }
    
    var hasTx: Bool { !txId.isEmpty }
    
    var hasDataId: Bool { data.hasId }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        janus <-- json[JanusMessage.Key.janus]
        txId <-- json[JanusMessage.Key.transaction]
        data <-- json[JanusMessage.Key.data]
        error <-- json[JanusMessage.Key.error]
    }
}

class JanusTxResponseMessageData: Codable, ArrowParsable {
    
    var id: Int = 0
    
    var hasId: Bool { id != 0 }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        id <-- json[JanusMessage.Key.id]
    }
}

class JanusTxResponseMessageError: Codable, ArrowParsable {
    
    var code: Int = 0
    
    var reason = ""
    
    var hasError: Bool { code != 0 && !reason.isEmpty }

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        code <-- json[JanusMessage.Key.code]
        reason <-- json[JanusMessage.Key.reason]
    }
}
