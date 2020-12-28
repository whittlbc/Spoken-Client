//
//  MemberState.swift
//  Chat
//
//  Created by Ben Whittle on 12/28/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Supported member states.
enum MemberState {
    case idle
    case previewing
    case recording(Bool) // (hasStarted)
    case recordingSending
    case recordingSent
    
    func isRecordingBased() -> Bool {
        switch self {
        case .recording(_):
            return true
            
        case .recordingSending,
             .recordingSent:
            return true
            
        default:
            return false
        }
    }
    
    static func ===(lhs: MemberState, rhs:MemberState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.previewing, .previewing):
            return true
        case (.recording(let la), .recording(let ra)):
            return la == ra
        case (.recordingSending, .recordingSending):
            return true
        case (.recordingSent, .recordingSent):
            return true
        default:
            return false
        }
    }
    
    static func ==(lhs: MemberState, rhs:MemberState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.previewing, .previewing):
            return true
        case (.recording, .recording):
            return true
        case (.recordingSending, .recordingSending):
            return true
        case (.recordingSent, .recordingSent):
            return true
        default:
            return false
        }
    }
    
    static func !=(lhs: MemberState, rhs:MemberState) -> Bool {
        return (lhs == rhs) == false
    }
}

