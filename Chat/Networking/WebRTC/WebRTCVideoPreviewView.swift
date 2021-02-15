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
        super.renderFrame(frame)
        lastFrame = frame
    }
}
