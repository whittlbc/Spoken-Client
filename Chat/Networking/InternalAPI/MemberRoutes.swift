//
//  MemberRoutes.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

// Member requests.
extension InternalAPI {
    
    // Fetch all members for a workspace.
    func fetchMembers(forWorkspace workspace: Workspace) -> AnyPublisher<Member, Error> {
        get(Resources.members, params: ["workspace_id": workspace.id])
    }
}
