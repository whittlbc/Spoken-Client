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
    var memberIds = [String]()
    var channelIds = [String]()
    
    var channels: [Channel]?
}
