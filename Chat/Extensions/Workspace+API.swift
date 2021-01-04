//
//  Workspace+API.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

extension Workspace {
    
    // Fetch a workspace's channels.
    func fetchChannels() -> AnyPublisher<[Channel], Error> {
        api.fetchChannels(forWorkspace: self)
    }
}
