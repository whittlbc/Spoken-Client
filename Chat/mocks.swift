//
//  mocks.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

// Mock data for local development.
enum Mocks {
    
    enum Users {

        static let ben = User(
            id: "a",
            email: "ben@gmail.com",
            name: Name(
                first: "Ben",
                last: "Whittle"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/ben-whittle/avatar.jpg"
        )
        
        static let tyler = User(
            id: "b",
            email: "tyler@gmail.com",
            name: Name(
                first: "Tyler",
                last: "Whittle"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/tyler-whittle/tyler.jpg"
        )
        
        static let andrea = User(
            id: "c",
            email: "andrea@gmail.com",
            name: Name(
                first: "Andrea",
                last: "Salazar"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/andrea-salazar/color-avatar.jpg"
        )
        
        static let josh = User(
            id: "d",
            email: "josh@gmail.com",
            name: Name(
                first: "Josh",
                last: "Jeans"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/josh-jeans/color-avatar.jpg"
        )
        
        static let current = ben
    }
    
    enum Workspaces {
        
        static let current = Workspace(
            id: "a",
            name: "My Workspace"
        )
    }
    
    enum Members {
        static let ben = Member(id: "ben", user: Users.ben)
        static let tyler = Member(id: "tyler", user: Users.tyler)
        static let andrea = Member(id: "andrea", user: Users.andrea)
        static let josh = Member(id: "josh", user: Users.josh)
    }
    
    enum Channels {
        
        static let all: [Channel] = [
            Channel(id: "a", members: [Members.ben, Members.tyler]),
            Channel(id: "b", members: [Members.ben, Members.andrea]),
            Channel(id: "c", members: [Members.ben, Members.josh])
        ]
    }
}
