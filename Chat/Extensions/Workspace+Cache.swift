//
//  Workspace+Cache.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Cache

extension Cache {

    // Workspaces cache
    enum Workspaces {
        
        // Storage instance.
        static let storage: Storage<String, Workspace> = Cache.newStorage(Workspace.self)
        
        // Standardized workspace cache keys.
        enum Keys {
            static let current = "current"
        }
        
        // Get current workspace.
        static func getCurrent() -> Workspace? {
            try? Workspaces.storage.object(forKey: Keys.current)
        }
        
        // Set current workspace.
        static func setCurrent(_ workspace: Workspace) {
            do {
                try Workspaces.storage.setObject(
                    Workspaces.prepWorkspaceForStorage(workspace),
                    forKey: Keys.current
                )
            } catch {
                logger.error("Error setting current workspace in Workspaces cache: \(error)")
            }
        }
        
        // Prepare workspace instance to be stored in cache.
        static func prepWorkspaceForStorage(_ workspace: Workspace) -> Workspace {
            var ws = workspace
            
            // Clear workspace members -- don't want to cache those.
            ws.members.removeAll()
            
            return ws
        }
    }
}
