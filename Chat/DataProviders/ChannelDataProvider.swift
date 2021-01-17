//
//  ChannelDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/15/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking
import Combine

class ChannelDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {
    
    func list(ids: [String], withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        guard withMembers else {
            return list(ids: ids)
        }
        
        return list(ids: ids)
            .flatMap({ self.loadMembers(for: $0, withUsers: withUsers) })
            .eraseToAnyPublisher()
    }
    
    private func loadMembers(for models: [T], withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        let channels = models as! [Channel]
                
        return dataProvider.member
            .list(ids: channels.flatMap(\.memberIds).unique(), withUsers: withUsers)
            .map { members in
                let membersMap = members.reduce(into: [String: Member]()) { $0[$1.id] = $1 }
                var newChannels = [Channel]()
                
                for channel in channels {
                    var newChannel = channel
                    var channelMembers = [Member]()
                    
                    for memberId in channel.memberIds {
                        if let member = membersMap[memberId] {
                            channelMembers.append(member)
                        }
                    }
                    
                    newChannel.members = channelMembers
                    newChannels.append(newChannel)
                }
                
                return newChannels as! [T]
            }
            .eraseToAnyPublisher()
    }
}
