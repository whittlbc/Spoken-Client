//
//  WorkspaceRoutes.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

// Workspace resource.
extension InternalAPI.Resources {
    static let workspace = "/workspace"
    static let workspaces = "/workspaces"
}

// Workspace requests.
extension InternalAPI {
    
    // Fetch all workspaces for current user.
    func fetchWorkspaces() -> AnyPublisher<[Workspace], Error> {
        get(Resources.workspaces)
    }
}
