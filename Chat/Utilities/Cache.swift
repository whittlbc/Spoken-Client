//
//  Cache.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Cache

// Cache manager and creator.
public enum Cache {

    // On-Disk storage configuration
    private static let diskConfig = DiskConfig(name: Config.appBundleID)

    // In-memory storage configuration.
    private static let memoryConfig = MemoryConfig(countLimit: 50, totalCostLimit: 0)

    // Create new model-specific cache storage.
    static func newModelStorage<T: Codable>(_ model: T.Type) -> Storage<String, T> {
        do {
            let cache: Storage<String, T> = try Storage(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                transformer: TransformerFactory.forCodable(ofType: model)
            )
            
            return cache
        } catch {
            fatalError("Failed to create new model cache for type \(model): \(error)")
        }
    }
}
