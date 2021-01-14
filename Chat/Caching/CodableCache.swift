//
//  CodableCache.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Cache

class CodableCache<T: Codable> {

    let storage: Storage<String, T>
    
    init(storage: Storage<String, T>) {
        self.storage = storage
    }

    func get(forKey key: String) -> T? {
        try? storage.object(forKey: key)
    }

    func set(_ object: T, forKey key: String) throws {
        do {
            try storage.setObject(object, forKey: key)
        } catch {
            logger.error("\(error)")
            throw CacheError.writeFailed(key: key)
        }
    }
}
