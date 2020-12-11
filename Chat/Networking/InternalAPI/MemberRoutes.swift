//
//  MemberRoutes.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

// Member resource.
extension InternalAPI.Resources {
    static let member = "/member"
    static let members = "/members"
}

// Member requests.
extension InternalAPI {
    
    // Fetch all members for a workspace.
    func fetchMembers(forWorkspace workspace: Workspace) -> AnyPublisher<[Member], Error> {
        get(Resources.members, params: ["workspace_id": workspace.id])
    }
}
