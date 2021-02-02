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
    
    func get(id: String, withUser: Bool = false) -> AnyPublisher<T, Error> {
        if !withUser {
            return super.get(id: id)
        }
        
        return super.get(id: id)
            .flatMap({ self.loadUser(for: $0) })
            .eraseToAnyPublisher()
    }
    
    func list(ids: [String], withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        if !withUsers {
            return list(ids: ids)
        }
        
        return list(ids: ids)
            .flatMap({ self.loadUsers(for: $0) })
            .eraseToAnyPublisher()
    }
    
    private func loadUser(for model: T) -> AnyPublisher<T, Error> {
        var member = model as! Member
                
        return dataProvider.user
            .get(id: member.userId)
            .map { user in
                member.user = user
                return member as! T
            }
            .eraseToAnyPublisher()
    }
    
    private func loadUsers(for models: [T]) -> AnyPublisher<[T], Error> {
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
