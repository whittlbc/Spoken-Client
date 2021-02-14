//
//  JanusJSEP.swift
//  Chat
//
//  Created by Ben Whittle on 2/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC
import Arrow

class JanusJSEP: Codable, ArrowParsable {
    
    var type = ""
    
    var sdp = ""
    
    var isEmpty: Bool { sdp.isEmpty }
        
    convenience init(sdp: RTCSessionDescription) {
        self.init()
        self.type = RTCSessionDescription.string(for: sdp.type)
        self.sdp = sdp.sdp
    }
    
    required init() {}

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    func deserialize(_ json: JSON) {
        type <-- json["type"]
        sdp <-- json["sdp"]
    }
        
    func toSDP() -> RTCSessionDescription {
        RTCSessionDescription(type: RTCSessionDescription.type(for: type), sdp: sdp)
    }
}
