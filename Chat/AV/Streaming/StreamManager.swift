//
//  AVStreamer.swift
//  Chat
//
//  Created by Ben Whittle on 2/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import WebRTC
import Combine

class StreamManager {
        
    static let videoConfig = WebRTCVideoSourceConfig(
        width: 800,
        height: 800,
        fps: 30
    )

    // WebRTC client for room connections.
    var client: WebRTCClient!

    func streamNewMessage(_ message: Message) {
        connectToRoom(message.uploadId)
    }
    
    func stopMessage() {
        teardownClient()
    }
    
    func renderLocalStream(to renderer: RTCVideoRenderer) {
        client.renderLocalStream(to: renderer)
    }
    
    func cacheLastVideoFrame() -> NSImage? {
        guard let videoPreviewView = client.localVideoRenderer as? WebRTCVideoPreviewView,
              let lastFrame = videoPreviewView.lastFrame,
              let image = lastFrame.nsImage else {
            return nil
        }
        
        dataProvider.user.setVideoPlaceholder(id: Session.currentUserId!, image: image)
        
        return image
    }
    
    private func connectToRoom(_ roomId: Int) {
        // Tear down existing WebRTC client.
        teardownClient()
        
        // Create a new WebRTC client for this room.
        client = WebRTCClient(
            roomId: roomId,
            videoSourceConfig: StreamManager.videoConfig
        )
    }
    
    private func teardownClient() {
        client = nil
    }
}
