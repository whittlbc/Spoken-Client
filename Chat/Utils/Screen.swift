//
//  Screen.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class Screen {
    
    static func getHeight() -> Int {
        let currentScreen = getCurrentScreen()
        return Int(currentScreen.frame.height)
    }
    
    static func getWidth() -> Int {
        let currentScreen = getCurrentScreen()
        return Int(currentScreen.frame.width)
    }
    
    static func getCurrentScreen() -> NSScreen {
        if let screen = NSScreen.main {
            return screen
        }

        return NSScreen.screens[0]
    }
}
