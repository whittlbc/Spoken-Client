//
//  ChannelRoutes.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

// Channel resource.
extension InternalAPI.Resources {
    static let channel = "/channel"
    static let channels = "/channels"
}

// Channel requests.
extension InternalAPI {
    
    // Fetch all channels for a workspace.
    func fetchChannels(forWorkspace workspace: Workspace) -> AnyPublisher<[Channel], Error> {
        get(Resources.channels, params: ["workspace_id": workspace.id])
    }
}
