//
//  WindowControllerManager.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class WindowControllerManager {
    
    var sidebarWindowController: SidebarWindowController?
    
    func launchInitialWindow() {
        // Either show the sidebar or the sign-in window based on the current user's auth status.
        api.isAuthed() ? showSidebarWindow() : showSignInWindow()
    }

    func showSidebarWindow() {
        // Upsert the sidebarWindowController property.
        sidebarWindowController = sidebarWindowController ?? SidebarWindowController()
        
        // Show the sidebar window.
        sidebarWindowController!.showWindow(self)
    }
    
    func showSignInWindow() {
        logger.info("Showing sign-in window...")
    }
}
