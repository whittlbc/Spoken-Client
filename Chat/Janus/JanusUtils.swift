//
//  JanusUtils.swift
//  Chat
//
//  Created by Ben Whittle on 2/6/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

class JanusConnection: NSObject {
    var handleId: NSNumber?
    var connection: RTCPeerConnection?
    var videoTrack: RTCVideoTrack?
//    var videoView: RTCEAGLVideoView?
}
