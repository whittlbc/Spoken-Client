//
//  VideoSession.swift
//  Chat
//
//  Created by Ben Whittle on 3/31/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AgoraRtcKit

class VideoSession {
    
    static let previewUid: UInt = 0
    
    static func newLocalSession(videoView: VideoView) -> VideoSession {
        return VideoSession(videoView: videoView, uid: VideoSession.previewUid, type: .local)
    }
    
    enum SessionType {
        case local
        case remote
        
        var isLocal: Bool {
            switch self {
            
            // Local stream
            case .local:
                return true
            
            // Remote stream
            case .remote:
                return false
            }
        }
    }
    
    var uid: UInt
    
    var type: SessionType

    var videoView: VideoView
    
    var videoCanvas: AgoraRtcVideoCanvas!
    
    init(videoView: VideoView, uid: UInt, type: SessionType = .remote) {
        self.videoView = videoView
        self.uid = uid
        self.type = type
                
        // Create Agora video canvas and attach video view.
        createVideoCanvas()
    }
    
    private func createVideoCanvas() {
        videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = videoView
        videoCanvas.renderMode = .hidden
    }
}
