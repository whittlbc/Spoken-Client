//
//  ChannelState.swift
//  Chat
//
//  Created by Ben Whittle on 12/28/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Supported channel states.
enum ChannelState {
    case idle
    case previewing
    case recording(RecordingStatus)
    
    // Case equality check + associated value equality checks
    static func ===(lhs: ChannelState, rhs: ChannelState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.previewing, .previewing):
            return true
        case (.recording(let lstatus), .recording(let rstatus)):
            return lstatus == rstatus
        default:
            return false
        }
    }
    
    // Case inequality check + associated value inequality checks
    static func !==(lhs: ChannelState, rhs: ChannelState) -> Bool {
        return (lhs === rhs) == false
    }
    
    // Case equality check
    static func ==(lhs: ChannelState, rhs: ChannelState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.previewing, .previewing):
            return true
        case (.recording, .recording):
            return true
        default:
            return false
        }
    }
    
    // Case inequality check.
    static func !=(lhs: ChannelState, rhs: ChannelState) -> Bool {
        return (lhs == rhs) == false
    }
}

// Supported statuses of an active recording.
enum RecordingStatus {
    case initializing
    case started
    case cancelling
    case sending
    case sent
    case finished
}
