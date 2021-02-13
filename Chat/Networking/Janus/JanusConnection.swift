//
//  JanusConnection.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

class JanusConnection {
    
    var handleId: Int!
    
    var peerConnection: RTCPeerConnection!
    
    var videoTrack: RTCVideoTrack?
        
    init(handleId: Int, peerConnection: RTCPeerConnection, videoTrack: RTCVideoTrack? = nil) {
        self.handleId = handleId
        self.peerConnection = peerConnection
        self.videoTrack = videoTrack
    }
}
