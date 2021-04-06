//
//  WorkspaceDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking
import Combine

class WorkspaceDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {
    
    func get(id: String, withChannels: Bool = false, withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<T, Error> {
        if !withChannels {
            return get(id: id)
        }
        
        return get(id: id)
            .flatMap({ self.loadChannels(for: $0, withMembers: withMembers, withUsers: withUsers) })
            .eraseToAnyPublisher()
    }
    
    func list(ids: [String], withChannels: Bool = false, withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        if !withChannels {
            return list(ids: ids)
        }
        
        return list(ids: ids)
            .flatMap({ self.loadChannels(forList: $0, withMembers: withMembers, withUsers: withUsers) })
            .eraseToAnyPublisher()
    }

    func currentWorkspaces(withChannels: Bool = false, withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        return dataProvider.user
            .current()
            .tryMap { user in
                guard user.workspaceIds.count > 0 else {
                    throw DataProviderError.notFound
                }

                return user.workspaceIds
            }
            .flatMap({ self.list(ids: $0, withChannels: withChannels, withMembers: withMembers, withUsers: withUsers)            })
            .eraseToAnyPublisher()
    }

    private func loadChannels(for model: T, withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<T, Error> {
        var workspace = model as! Workspace
        
        return dataProvider.channel
            .list(ids: workspace.channelIds, withMembers: withMembers, withUsers: withUsers)
            .map { channels in
                workspace.channels = channels
                return workspace as! T
            }
            .eraseToAnyPublisher()
    }
    
    private func loadChannels(forList models: [T], withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<[T], Error> {
        let workspaces = models as! [Workspace]
                
        return dataProvider.channel
            .list(ids: workspaces.flatMap(\.channelIds).unique(), withMembers: withMembers, withUsers: withUsers)
            .map { channels in
                let channelsMap = channels.reduce(into: [String: Channel]()) { $0[$1.id] = $1 }
                var newWorkspaces = [Workspace]()
                
                for workspace in workspaces {
                    var newWorkspace = workspace
                    var workspaceChannels = [Channel]()
                    
                    for channelId in workspace.channelIds {
                        if let channel = channelsMap[channelId] {
                            workspaceChannels.append(channel)
                        }
                    }
                    
                    newWorkspace.channels = workspaceChannels
                    newWorkspaces.append(newWorkspace)
                }
                
                return newWorkspaces as! [T]
            }
            .eraseToAnyPublisher()
    }
}
