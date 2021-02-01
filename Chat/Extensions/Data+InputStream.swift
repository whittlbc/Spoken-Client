//
//  Data+InputStream.swift
//  Chat
//
//  Created by Ben Whittle on 1/31/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

extension Data {
    /**
        Consumes the specified input stream for up to `byteCount` bytes,
        creating a new Data object with its content.
        - Parameter reading: The input stream to read data from.
        - Parameter byteCount: The maximum number of bytes to read from `reading`.
        - Note: Does _not_ close the specified stream.
    */
    init(reading input: InputStream, for byteCount: Int) {
        self.init()
        input.open()

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        let read = input.read(buffer, maxLength: byteCount)
        
        self.append(buffer, count: read)
        
        buffer.deallocate()
    }
}
