//
//  Workspace.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct Workspace: Model {
    
    static var modelName = "workspace"

    var id = ""
    var name = ""
    var slug = ""
    var memberIds = [String]()
    var channelIds = [String]()
    
    var members = [Member]()
    var channels = [Channel]()
    
    func forCache() -> Workspace {
        var workspace = self
        workspace.members = []
        workspace.channels = []
        return workspace
    }
}
