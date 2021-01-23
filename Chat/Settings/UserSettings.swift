//
//  UserSettings.swift
//  Chat
//
//  Created by Ben Whittle on 1/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

// User settings and defaults.
enum UserSettings {
    
    // Format a user setting name with the namespace it belongs to.
    static func formatKey(_ nsp: String, _ setting: String) -> String {
        [nsp, setting].joined(separator: ":")
    }
    
    // Speech recognition settings.
    enum SpeechRecognition {
        
        // Speech recognition namespace.
        static let nsp = "sr"

        // Whether the user wants to use speech recognition to prompt channel recordings.
        @UserDefault(key: UserSettings.formatKey(nsp, "isEnabled"))
        static var isEnabled = false
    }
    
    // Video settings.
    enum Video {
        
        // Video namespace.
        static let nsp = "video"

        // Whether the user wants to enable video for new recordings or during conversation.
        @UserDefault(key: UserSettings.formatKey(nsp, "useCamera"))
        static var useCamera = true
    }
}
