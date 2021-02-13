//
//  AVStreamer.swift
//  Chat
//
//  Created by Ben Whittle on 2/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import WebRTC

class StreamManager {
    
    static let videoConfig = WebRTCVideoSourceConfig(
        width: Int(ChannelAvatarView.Style.VideoPreviewLayer.diameter),
        height: Int(ChannelAvatarView.Style.VideoPreviewLayer.diameter),
        fps: 30
    )

    // WebRTC client for room connections.
    var client: WebRTCClient!
    
    func streamNewMessage(_ message: Message) {
        connectToRoom(message.uploadId)
    }
    
    func stopMessage() {
        client = nil
    }
    
    func renderLocalStream(to renderer: RTCVideoRenderer) {
        client.renderLocalStream(to: renderer)
    }
    
    private func connectToRoom(_ roomId: Int) {
        // Tear down existing WebRTC client.
        client = nil
        
        // Create a new WebRTC client for this room.
        client = WebRTCClient(
            roomId: roomId,
            videoSourceConfig: StreamManager.videoConfig
        )
    }
}

