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

    var currentKey: String { "\(T.modelName):current" }
    
    func get(id: String, withChannels: Bool = false, withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<T, Error> {
        guard withChannels else {
            return get(id: id)
        }
        
        return get(id: id)
            .flatMap({ self.loadChannels(for: $0, withMembers: withMembers, withUsers: withUsers) })
            .eraseToAnyPublisher()
    }

    func current(withChannels: Bool = false, withMembers: Bool = false, withUsers: Bool = false) -> AnyPublisher<T, Error> {
        // Get the workspace using the cached current workspace id (if it exists).
        if let currentWorkspaceId = CacheManager.stringCache.get(forKey: currentKey) {
            return get(id: currentWorkspaceId, withChannels: withChannels, withMembers: withMembers, withUsers: withUsers)
        }

        // Get the current user's first workspace and cache its id as the current workspace id.
        return dataProvider.user
            .current()
            .tryMap { user in
                guard user.workspaceIds.count > 0 else {
                    throw DataProviderError.notFound
                }
                
                return user.workspaceIds[0]
            }
            .flatMap({ self.get(id: $0, withChannels: withChannels, withMembers: withMembers, withUsers: withUsers) })
            .handleEvents(receiveOutput: { [weak self] result in
                self?.setCurrent(id: result.id)
            })
            .eraseToAnyPublisher()
    }
    
    func setCurrent(id: String) {
        do {
            try CacheManager.stringCache.set(id, forKey: currentKey)
        } catch CacheError.writeFailed(_) {
            logger.error("Writing current \(T.modelName) id in string cache failed.")
        } catch {
            logger.error("Unknown error while caching current \(T.modelName) id in string cache: \(error)")
        }
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
}
