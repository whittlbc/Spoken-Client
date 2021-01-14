//
//  WorkspaceDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking

class WorkspaceDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {

    var currentKey: String { "\(T.modelName):current" }
    
    func current(then provide: @escaping ProvideOne) {
        // Provide current workspace using current workspace id if it already exists.
        if let currentWorkspaceId = CacheManager.stringCache.get(forKey: currentKey) {
            get(id: currentWorkspaceId, then: provide)
            return
        }
        
        // Get current user.
        dataProvider.user.current { [weak self] currentUser, error in
            // Handle error getting current user.
            if let err = error {
                provide(nil, err)
                return
            }
            
            // Get current user's ordered workspace ids.
            let workspaceIds = currentUser?.workspaceIds ?? [String]()
            
            // If no workspaces exist yet, return nil with no error.
            if workspaceIds.isEmpty {
                provide(nil, nil)
                return
            }
            
            // Set current workspace to first workspace id.
            do {
                try self?.setCurrent(id: workspaceIds[0])
            } catch {
                provide(nil, error as? DataProviderError)
                return
            }
            
            // Call this function again now that we now the current workspace key is cached.
            self?.current(then: provide)
        }
    }
    
    func setCurrent(id: String) throws {
        do {
            try CacheManager.stringCache.set(id, forKey: currentKey)
        } catch CacheError.writeFailed(key: let key) {
            logger.error("Writing current \(T.modelName) id in string cache failed.")
            throw DataProviderError.cachingFailed(key: key)
        } catch {
            logger.error("Unknown error while caching current \(T.modelName) id in string cache: \(error)")
            throw DataProviderError.unknownError
        }
    }
}
