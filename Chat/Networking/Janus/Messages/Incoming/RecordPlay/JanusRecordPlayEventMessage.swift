//
//  JanusRecordPlayEventMessage.swift
//  Chat
//
//  Created by Ben Whittle on 3/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusRecordPlayEventMessage: Codable, ArrowParsable {
    
    static func fromJSON(_ json: JSON) -> Self {
        let message = Self()
        message.deserialize(json)
        return message
    }
    
    var janus = ""
    
    var sender: Int = 0
        
    var jsep = JanusJSEP()
            
    var hasSender: Bool { sender != 0 }
        
    var hasJSEP: Bool { !jsep.isEmpty }
            
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        janus <-- json[JanusMessage.Key.janus]
        sender <-- json[JanusMessage.Key.sender]
        jsep <-- json[JanusMessage.Key.jsep]
    }
}

class JanusRecordPlayEventMessagePlugin: Codable, ArrowParsable {

    var data = JanusRecordPlayEventMessagePluginData()
    
    var publishers = [JanusRecordPlayEventMessagePluginPublisher]()
    
    var leaving: Int = 0
    
    var hasPublishers: Bool { publishers.count > 0 }

    var didJoin: Bool { data.didJoin }
    
    var didLeave: Bool { leaving != 0 }

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        data <-- json[JanusMessage.Key.data]
        publishers <-- json[JanusMessage.Key.publishers]
        leaving <-- json[JanusMessage.Key.leaving]
    }
}

class JanusRecordPlayEventMessagePluginData: Codable, ArrowParsable {
    
    enum RecordPlayStatus: String {
        case joined
    }
    
    var videoRoom = ""
    
    var didJoin: Bool { getRecordPlayStatus() == .joined }
    
    func getRecordPlayStatus() -> RecordPlayStatus? {
        RecordPlayStatus(rawValue: videoRoom)
    }

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        videoRoom <-- json[JanusMessage.Key.videoRoom]
    }
}

class JanusRecordPlayEventMessagePluginPublisher: Codable, ArrowParsable {
    
    var feedId: Int = 0
    
    var display = ""
    
    var hasFeed: Bool { feedId != 0 && !display.isEmpty }

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        feedId <-- json[JanusMessage.Key.id]
        display <-- json[JanusMessage.Key.display]
    }
}
