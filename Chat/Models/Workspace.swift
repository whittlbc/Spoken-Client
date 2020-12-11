//
//  Workspace.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct Workspace: Identifiable, Codable {
    var id = ""
    var name = ""
    var members = [Member]()
    
    // Get current workspace from cache.
    static var current: Workspace? {
        // Cache.Workspaces.getCurrent()
        Mocks.Workspaces.current
    }
}
