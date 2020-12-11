//
//  EndpointResources.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

extension InternalAPI {
    
    // Model endpoint resources
    enum Resources {
        // Workspace resouce
        static let workspace = "/workspace"
        static let workspaces = "/workspaces"
        
        // Member resources
        static let member = "/member"
        static let members = "/members"
    }
}
