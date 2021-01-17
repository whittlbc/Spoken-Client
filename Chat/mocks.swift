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
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/ben-whittle/avatar.jpg",
            workspaceIds: ["a"]
        )
                
        static let tyler = User(
            id: "b",
            email: "tyler@gmail.com",
            name: Name(
                first: "Tyler",
                last: "Whittle"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/tyler-whittle/tyler.jpg",
            workspaceIds: ["a"]
        )
        
        static let andrea = User(
            id: "c",
            email: "andrea@gmail.com",
            name: Name(
                first: "Andrea",
                last: "Salazar"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/andrea-salazar/color-avatar.jpg",
            workspaceIds: ["a"]
        )
        
        static let josh = User(
            id: "d",
            email: "josh@gmail.com",
            name: Name(
                first: "Josh",
                last: "Jeans"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/team/josh-jeans/color-avatar.jpg",
            workspaceIds: ["a"]
        )
        
        static let benTaylor = User(
            id: "e",
            email: "ben.taylor@gmail.com",
            name: Name(
                first: "Ben",
                last: "Taylor"
            ),
            avatar: "https://dacxe0nzqx93t.cloudfront.net/random/ben-taylor-avatar.jpg",
            workspaceIds: ["a"]
        )

        static let current = ben
    }
    
    enum Workspaces {
        
        static let current = Workspace(
            id: "a",
            name: "My Workspace",
            memberIds: [
                Members.ben.id,
                Members.tyler.id,
                Members.andrea.id,
                Members.josh.id,
                Members.benTaylor.id
            ],
            channelIds: Channels.all.map({ $0.id })
        )
    }
    
    enum Members {
        static let ben = Member(id: "ben", userId: Users.ben.id)
        static let tyler = Member(id: "tyler", userId: Users.tyler.id)
        static let andrea = Member(id: "andrea", userId: Users.andrea.id)
        static let josh = Member(id: "josh", userId: Users.josh.id)
        static let benTaylor = Member(id: "ben-taylor", userId: Users.benTaylor.id)
    }
    
    enum Channels {
        
        static let all: [Channel] = [
            Channel(id: "a", memberIds: [Members.ben.id, Members.tyler.id]),
            Channel(id: "b", memberIds: [Members.ben.id, Members.benTaylor.id]),
            Channel(id: "c", memberIds: [Members.ben.id, Members.andrea.id]),
            Channel(id: "d", memberIds: [Members.ben.id, Members.josh.id])
        ]
    }
}
