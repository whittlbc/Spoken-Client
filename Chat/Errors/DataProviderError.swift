//
//  DataProviderError.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

public enum DataProviderError: Error {
    case cacheObjectNotFound(key: String)
    case cachingFailed(key: String)
    case vendingFailed
    case unknownError
}
