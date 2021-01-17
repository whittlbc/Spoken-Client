//
//  MemberDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/16/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking
import Combine

class MemberDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {
    
    func list(ids: [String], withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        guard withUsers else {
            return list(ids: ids)
        }
        
        return list(ids: ids)
            .flatMap({ self.loadUsers(for: $0) })
            .eraseToAnyPublisher()
    }
    
    private func loadUsers(for models: [T], withUser: Bool = false) -> AnyPublisher<[T], Error> {
        let members = models as! [Member]
                
        return dataProvider.user
            .list(ids: members.map(\.userId).unique())
            .map { users in
                let usersMap = users.reduce(into: [String: User]()) { $0[$1.id] = $1 }
                var newMembers = [Member]()
                
                for member in members {
                    var newMember = member
                    
                    if let user = usersMap[member.userId] {
                        newMember.user = user
                    }
                    
                    newMembers.append(newMember)
                }
                
                return newMembers as! [T]
            }
            .eraseToAnyPublisher()
    }
}
