//
//  NSImage+Load.swift
//  Chat
//
//  Created by Ben Whittle on 1/13/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

extension NSImage {
    
    static func forKey(_ key: String, remoteURL: String) -> AnyPublisher<NSImage, Error> {
        // Attempt to get an image from the image cache for the provided key.
        if let image = CacheManager.imageCache.get(forKey: key) {
            return Just(image)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Create a URL object from the remote URL string.
        guard let url = URL(string: remoteURL) else {
            return Fail(error: ImageError.invalidURL)
                .eraseToAnyPublisher()
        }

        // Fetch and publish image from remote url.
        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .tryMap { data in
                guard let image = NSImage(data: data) else {
                    throw ImageError.requestFailed
                }

                // Cache image for given key.
                try? CacheManager.imageCache.set(image, forKey: key)

                return image
            }
            .eraseToAnyPublisher()
    }
}

