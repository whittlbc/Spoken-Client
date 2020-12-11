//
//  User+Cache.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Cache

extension Cache {

    // Users cache
    enum Users {
        
        // Storage instance.
        static let storage: Storage<String, User> = Cache.newModelStorage(User.self)
        
        // Standardized user cache keys.
        enum Keys {
            static let current = "current"
        }
        
        // Get current user.
        static func getCurrent() -> User? {
            try? Users.storage.object(forKey: Keys.current)
        }
        
        // Set current user.
        static func setCurrent(_ user: User) {
            do {
                try Users.storage.setObject(user, forKey: Keys.current)
            } catch {
                logger.error("Error setting current user in cache: \(error)")
            }
        }
    }
}
