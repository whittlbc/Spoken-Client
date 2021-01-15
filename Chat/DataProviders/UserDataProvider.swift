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
    
    func current() -> AnyPublisher<T, Error> {
        // Get current user id from string cache.
        guard let currentUserId = CacheManager.stringCache.get(forKey: currentKey) else {
            return Fail(error: DataProviderError.cacheObjectNotFound(key: currentKey))
                .eraseToAnyPublisher()
        }
        
        // Get user for current user id.
        return get(id: currentUserId)
    }
        
    func avatar(id: String, then handler: @escaping (NSImage?) -> Void) {
        handler(nil)
//        get(id: id) { [weak self] result, error in
//            guard error == nil, let user = result as? User, let key = self?.avatarImageKey(id: user.id) else {
//                handler(nil)
//                return
//            }
//
//            // Resolve the image from either the cache or the remote url.
//            NSImage.forKey(key, remoteURL: user.avatar) { image in
//                handler(image)
//            }
//        }
    }
}
