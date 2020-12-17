//
//  Screen.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Device screen utility functions.
public enum Screen {
    
    // Get height of screen.
    static func getHeight() -> Int {
        let currentScreen = Screen.getCurrentScreen()
        return Int(currentScreen.frame.height)
    }
    
    // Get width of screen.
    static func getWidth() -> Int {
        let currentScreen = Screen.getCurrentScreen()
        return Int(currentScreen.frame.width)
    }
    
    // Get main screen of current device.
    static func getCurrentScreen() -> NSScreen {
        if let screen = NSScreen.main {
            return screen
        }

        return NSScreen.screens[0]
    }
}
