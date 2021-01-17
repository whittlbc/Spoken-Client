//
//  Member.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

struct Member: Model {
    
    static var modelName = "member"

    var id = ""
    var userId = ""
    
    var user: User?
    
    func forCache() -> Member {
        var member = self
        member.user = nil
        return member
    }
}
