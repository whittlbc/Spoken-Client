//
//  Jo b.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public class Job {
    
    var name: String { "job" }
    
    init() {}
    
    func run() {
        logger.debug("Running \(name)...")
    }
}
