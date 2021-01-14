//
//  CacheError.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

public enum CacheError: Error {
    case writeFailed(key: String)
}
