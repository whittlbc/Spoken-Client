//
//  WebRTCVideoPreviewView.swift
//  Chat
//
//  Created by Ben Whittle on 2/14/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC
import AVFoundation

class WebRTCVideoPreviewView: RTCMTLNSVideoView {
    
    var lastFrame: RTCVideoFrame?
        
    override func renderFrame(_ frame: RTCVideoFrame?) {
        // Pass up the frame, unmodified.
        super.renderFrame(frame)
        
        // Store reference to each frame that comes in.
        lastFrame = frame
    }

    override func draw(_ dirtyRect: NSRect) {
        layer?.anchorPoint = CGPoint(x: 1, y: 0)
        layer?.setAffineTransform(CGAffineTransform(scaleX: -1, y: 1))
        super.draw(dirtyRect)
    }
}
