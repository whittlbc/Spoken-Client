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
        api.isAuthed() ? showSidebarWindow() : showSignInWindow()
    }
    
    func showSidebarWindow() {
        let sidebarWindow = windowControllerManager.newSidebarWindow()
        sidebarWindow.showWindow(self)
        sidebarWindow.addChildWindows()
    }
    
    func showSignInWindow() {
        logger.info("Showing sign-in window...")
    }
}
