//
//  JanusEventMessage.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Arrow

class JanusEventMessage: JanusMessage {
    
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
    
    override func deserialize(_ json: JSON) {
        janus <-- json[JanusMessage.Key.janus]
        sender <-- json[JanusMessage.Key.sender]
        plugin <-- json[JanusMessage.Key.pluginData]
        jsep <-- json[JanusMessage.Key.jsep]
    }
}

class JanusEventMessagePlugin: JanusMessage {

    var data = JanusEventMessagePluginData()
    
    var publishers = [JanusEventMessagePluginPublisher]()
    
    var leaving: Int = 0
    
    var hasPublishers: Bool { publishers.count > 0 }

    var didJoin: Bool { data.didJoin }
    
    var didLeave: Bool { leaving != 0 }

    override func deserialize(_ json: JSON) {
        data <-- json[JanusMessage.Key.data]
        publishers <-- json[JanusMessage.Key.publishers]
        leaving <-- json[JanusMessage.Key.leaving]
    }
}

class JanusEventMessagePluginData: JanusMessage {
    
    enum VideoRoomStatus: String {
        case joined
    }
    
    var videoRoom = ""
    
    var didJoin: Bool { getVideoRoomStatus() == .joined }
    
    func getVideoRoomStatus() -> VideoRoomStatus? {
        VideoRoomStatus(rawValue: videoRoom)
    }

    override func deserialize(_ json: JSON) {
        videoRoom <-- json[JanusMessage.Key.videoRoom]
    }
}

class JanusEventMessagePluginPublisher: JanusMessage {
    
    var feedId: Int = 0
    
    var display = ""
    
    var hasFeed: Bool { feedId != 0 && !display.isEmpty }

    override func deserialize(_ json: JSON) {
        feedId <-- json[JanusMessage.Key.id]
        display <-- json[JanusMessage.Key.display]
    }
}
