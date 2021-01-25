//
//  AVRecorderState.swift
//  Chat
//
//  Created by Ben Whittle on 1/24/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import AVFoundation

enum AVRecorderState {
    case initialized
    case starting(AVCaptureSession, String)
    case started(String)
    case stopping

    // Case equality check
    static func ==(lhs: AVRecorderState, rhs: AVRecorderState) -> Bool {
        switch (lhs, rhs) {
        case (.initialized, .initialized):
            return true
        case (.starting, .starting):
            return true
        case (.started, .started):
            return true
        case (.stopping, .stopping):
            return true
        default:
            return false
        }
    }
    
    // Case inequality check.
    static func !=(lhs: AVRecorderState, rhs: AVRecorderState) -> Bool {
        return (lhs == rhs) == false
    }
}

struct AVRecorderStartStatus {
    var audio = false
    var video = false
}
