//
//  OutputStream+Data.swift
//  Chat
//
//  Created by Ben Whittle on 1/31/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

extension OutputStream {

    func write(data: Data) {
        _ = data.withUnsafeBytes {
            write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
        }
    }
}
