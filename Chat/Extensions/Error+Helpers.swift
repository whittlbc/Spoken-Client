//
//  Error+Helpers.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

extension Error {
    
    func describe() -> String {
        String(describing: self)
    }
}
