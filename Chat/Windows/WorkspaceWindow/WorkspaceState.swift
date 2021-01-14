//
//  WorkspaceState.swift
//  Chat
//
//  Created by Ben Whittle on 1/4/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

// Workspace window state.
enum WorkspaceState {
    case loading
    case noWorkspacesExist
    case loaded
    case failed(DataProviderError)
}
