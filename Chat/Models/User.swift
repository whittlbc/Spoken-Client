//
//  User.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct User: Identifiable, Codable {
    var uid = ""
    var email = ""
    var name = Name()
    var avatar = ""
    
    func fullName() -> String {
        let full = name.first + " " + name.last
        return full.trimmingCharacters(in: .whitespaces)
    }
    
    // Get current user from cache.
    static var current: User? {
        Cache.Users.getCurrent()
    }
}
