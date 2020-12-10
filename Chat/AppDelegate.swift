//
//  AppDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
 
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    let windowControllerManager = WindowControllerManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Figure out which direction to send the user based on whether they're logged in or not
        showSidebarWindow()
    }
    
    func showSidebarWindow() {
        let sidebarWindow = windowControllerManager.newSidebarWindow()
        sidebarWindow.showWindow(self)
        sidebarWindow.addChildWindows()
    }
}
