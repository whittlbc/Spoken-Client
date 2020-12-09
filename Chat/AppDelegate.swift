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
        showSidebarWindow(self)
        print(Config.env)
    }
    
    @objc func showSidebarWindow(_ sender: Any?) {
        let sidebarWindow = windowControllerManager.newSidebarWindow()
        sidebarWindow.showWindow(self)
        sidebarWindow.addChildWindows()
    }
}
