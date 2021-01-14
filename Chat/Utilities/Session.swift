//
//  Session.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

public enum Session {
    
    static var currentUserId: String? {
        CacheManager.stringCache.get(forKey: dataProvider.user.currentKey)
    }
}
