//
//  User.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct User: Model {

    static var modelName = "user"

    var id = ""
    var email = ""
    var name = Name()
    var avatar = ""
    var workspaceIds = [String]()

    var workspaces = [Workspace]()

    func fullName() -> String {
        let full = name.first + " " + name.last
        return full.trimmingCharacters(in: .whitespaces)
    }
    
    func forCache() -> User {
        var user = self
        user.workspaces = []
        return user
    }
}
