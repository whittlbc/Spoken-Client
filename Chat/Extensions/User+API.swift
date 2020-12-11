//
//  Workspace+API.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

extension User {
    
    // Fetch current user's workspaces.
    func fetchWorkspaces() -> AnyPublisher<[Workspace], Error> {
        api.fetchWorkspaces()
    }
}
