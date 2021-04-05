//
//  AppDelegate.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa
 
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    // Manager for all window controllers.
    private let windowControllerManager = WindowControllerManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Launch initial app window dependent on current user's auth status.
        windowControllerManager.launchInitialWindow()
        
        // Start job workers.
        startWorkers()
        
        // Start listening for pubsub messages.
        startPubsubManager()
    }
    
    private func startWorkers() {
        // Start file upload worker.
        fileUploadWorker.start()
    }
    
    private func startPubsubManager() {
        pubsubManager.start()
    }
}
