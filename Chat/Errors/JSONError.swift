//
//  JSONError.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

public enum JSONError: Error {
    case parsingFailed(String)
}
