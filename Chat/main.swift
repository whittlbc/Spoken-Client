//
//  main.swift
//  Chat
//
//  Created by Ben Whittle on 12/3/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

autoreleasepool {
    withExtendedLifetime(AppDelegate()) { delegate in
        // Get shared application.
        let app = NSApplication.shared
        
        // Set delegate to AppDelegate.
        app.delegate = delegate
                
        // Start the app.
        app.run()
    }
}
