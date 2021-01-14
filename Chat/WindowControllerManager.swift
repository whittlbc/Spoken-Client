//
//  WindowControllerManager.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Manager of all windows in this application.
class WindowControllerManager {
    
    // Controller for the main application window -- the sidebar.
    private var sidebarWindowController: SidebarWindowController?
    
    // Launch first window of the application.
    func launchInitialWindow() {
        // Either show the sidebar or the sign-in window based on the current user's auth status.
        api.isAuthed() ? showSidebarWindow() : showSignInWindow()
    }

    // Show the primary window of this application (i.e. the sidebar).
    func showSidebarWindow() {
        // Upsert the sidebarWindowController property.
        sidebarWindowController = sidebarWindowController ?? SidebarWindowController()
        
        // Show the sidebar window.
        sidebarWindowController!.showWindow(self)
    }
    
    // Show the sign-in window for unauthed users.
    func showSignInWindow() {
        logger.info("Showing sign-in window...")
    }
}
