//
//  UserDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking
import Combine

class UserDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {

    var currentKey: String { "\(T.modelName):current" }
    
    func avatarImageKey(id: String) -> String { "\(T.modelName):avatar:\(id)" }
    
    func videoPlaceholderImageKey(id: String) -> String { "\(T.modelName):video-placeholder:\(id)" }

    func current() -> AnyPublisher<T, Error> {
        // Ensure current user id exists in the string cache
        guard let currentUserId = Session.currentUserId else {
            // This should only fail if the user isn't logged in.
            return Fail(error: DataProviderError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        // Get user for current user id.
        return get(id: currentUserId)
    }
    
    func avatar(id: String) -> AnyPublisher<NSImage, Error> {
        get(id: id)
            .flatMap({ NSImage.forKey(self.avatarImageKey(id: id), remoteURL: ($0 as! User).avatar) })
            .mapError(imageErrorToDataProviderError)
            .eraseToAnyPublisher()
    }
    
    func videoPlaceholder(id: String) -> NSImage? {
        CacheManager.imageCache.get(forKey: videoPlaceholderImageKey(id: id))
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
}
