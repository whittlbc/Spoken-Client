//
//  JanusEventMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusEventMessage: Codable, ArrowParsable {
    
    static func fromJSON(_ json: JSON) -> Self {
        let message = Self()
        message.deserialize(json)
        return message
    }
    
    var janus = ""
    
    var sender: Int = 0
    
    var plugin = JanusEventMessagePlugin()
    
    var jsep = JanusJSEP()
    
    var publishers: [JanusEventMessagePluginPublisher] { plugin.publishers }
    
    var leavingFeedId: Int { plugin.leaving }
    
    var hasSender: Bool { sender != 0 }
    
    var hasPublishers: Bool { plugin.hasPublishers }
    
    var hasJSEP: Bool { !jsep.isEmpty }
    
    var handleDidJoin: Bool { plugin.didJoin }
    
    var feedDidLeave: Bool { plugin.didLeave }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        janus <-- json[JanusMessage.Key.janus]
        sender <-- json[JanusMessage.Key.sender]
        plugin <-- json[JanusMessage.Key.pluginData]
        jsep <-- json[JanusMessage.Key.jsep]
    }
}

class JanusEventMessagePlugin: Codable, ArrowParsable {

    var data = JanusEventMessagePluginData()
    
    var publishers = [JanusEventMessagePluginPublisher]()
    
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

class JanusEventMessagePluginData: Codable, ArrowParsable {
    
    enum VideoRoomStatus: String {
        case joined
    }
    
    var videoRoom = ""
    
    var didJoin: Bool { getVideoRoomStatus() == .joined }
    
    func getVideoRoomStatus() -> VideoRoomStatus? {
        VideoRoomStatus(rawValue: videoRoom)
    }

    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        videoRoom <-- json[JanusMessage.Key.videoRoom]
    }
}

class JanusEventMessagePluginPublisher: Codable, ArrowParsable {
    
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
