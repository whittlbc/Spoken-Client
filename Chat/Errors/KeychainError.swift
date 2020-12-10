//
//  KeychainError.swift
//  Chat
//
//  Created by Ben Whittle on 12/9/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation

public enum KeychainError: Error {
    case noToken
    case unexpectedTokenData
    case unhandledError(status: OSStatus)
}
